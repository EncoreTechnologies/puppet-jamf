require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_restricted_software).provide(:api, parent: Puppet::Provider::Jamf) do
  # lots of methods inherited from Puppet::Provider::Jamf

  # always need to define this in our implementation classes
  mk_resource_methods

  ##########################
  # private methods that we need to implement because we inherit from Puppet::Provider::Jamf

  # this method should retrieve an instance and return it as a hash
  # note: we explicitly do NOT cache within this method because we want to be
  #       able to call it both in initialize() and in flush() and return the current
  #       state of the resource from the API each time
  def read_instance
    resp = authorized_http_client.get(restricted_software_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    software_list = body_json['restricted_software']

    # find the category that matches our name
    matches = software_list.select { |ls| ls['name'] == resource[:name] }
    if matches.size >= 1
      software_id = matches.first['id']
      resp = authorized_http_client.get(restricted_software_url + "/id/#{software_id}",
                                        headers: { 'Accept' => 'application/json' })
      software_params = JSON.parse(resp.body)['restricted_software']['general']
      software_scope = JSON.parse(resp.body)['restricted_software']['scope']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: software_params['id'],
        name: software_params['name'],
        process_name: software_params['process_name'],
        match_exact_process_name: software_params['match_exact_process_name'],
        send_notification: software_params['send_notification'],
        kill_process: software_params['kill_process'],
        delete_executable: software_params['delete_executable'],
        display_message: software_params['display_message'],
        all_computers: software_scope['all_computers'],
        scoped_computers: software_scope['computers'],
        scoped_computer_groups: software_scope['computer_groups'],
        scoped_buildings: software_scope['buildings'],
        scoped_departments: software_scope['departments'],
        excluded_computers: software_scope['exclusions']['computers'],
        excluded_computer_groups: software_scope['exclusions']['computer_groups'],
        excluded_buildings: software_scope['exclusions']['buildings'],
        excluded_departments: software_scope['exclusions']['departments'],
        excluded_users: software_scope['exclusions']['users'],
      }
    else
      instance = {
        ensure: :absent,
        name: resource[:name],
      }
    end
    instance
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    case resource[:ensure]
    when :absent
      # don't delete if we can't find an instance that matches by name
      unless cached_instance[:id].nil?
        url = restricted_software_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        restricted_software: {
          general: {
            name: resource[:name],
            process_name: resource[:process_name],
            match_exact_process_name: resource[:match_exact_process_name],
            send_notification: resource[:send_notification],
            kill_process: resource[:kill_process],
            delete_executable: resource[:delete_executable],
            display_message: resource[:display_message],
          },
          scope: {
            all_computers: resource[:all_computers],
            computers: {
              computer: resource[:scoped_computers],
            },
            computer_groups: {
              computer_group: resource[:scoped_computer_groups],
            },
            buildings: {
              building: resource[:scoped_buildings],
            },
            departments: {
              department: resource[:scoped_departments],
            },
            exclusions: {
              computers: {
                computer: resource[:excluded_computers],
              },
              computer_groups: {
                computer_group: resource[:excluded_computer_groups],
              },
              buildings: {
                building: resource[:excluded_buildings],
              },
              departments: {
                department: resource[:excluded_departments],
              },
              users: {
                user: resource[:excluded_users],
              },
            },
          },
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(restricted_software_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(restricted_software_url + "/id/#{cached_instance[:id]}",
                                   body: body,
                                   headers: { 'Content-Type' => 'application/xml' })
      end
    end
  end

  ################
  # custom methods needed from above
  # NOTE: we must use a cookie in the header of every request made to
  #       cloud servers since they are clustered and we were running
  #       into refresh issues because subsequent calls are dependent upon
  #       earlier ones.
  def authorized_http_client
    @authorized_client ||= Puppet::X::HTTPHelper.new(auth_token: resource[:auth_token],
                                                     is_jamf_cloud: resource[:is_cloud],
                                                     jamf_cookie: resource[:jamf_cookie])
  end

  def restricted_software_url
    # create a URL based on our API URL
    @restricted_software_url ||= "#{resource[:api_url]}/JSSResource/restrictedsoftware"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an restricted_software_name attribute for cloud
  #       server management to operate correctly.
  def restricted_software_name
    resource[:is_cloud] ? resource[:restricted_software_name] : resource[:name]
  end
end

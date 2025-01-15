require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_computer_configuration_profile).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(computer_config_profile_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    config_profile_list = body_json['os_x_configuration_profiles']

    # find the category that matches our name
    matches = config_profile_list.select { |ls| ls['name'] == config_profile_name }
    if matches.size >= 1
      config_profile_id = matches.first['id']
      resp = authorized_http_client.get(computer_config_profile_url + "/id/#{config_profile_id}",
                                        headers: { 'Accept' => 'application/json' })
      config_profile_params = JSON.parse(resp.body)['os_x_configuration_profile']['general']
      config_profile_scope = JSON.parse(resp.body)['os_x_configuration_profile']['scope']
      payloads = config_profile_params['payloads']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: config_profile_params['id'],
        uuid: config_profile_params['uuid'],
        name: config_profile_params['name'],
        category: config_profile_params['category']['name'],
        description: config_profile_params['description'],
        distribution_method: config_profile_params['distribution_method'],
        user_removable: config_profile_params['user_removable'],
        level: config_profile_params['level'],
        redeploy_on_update: config_profile_params['redeploy_on_update'],
        # if the payloads is a good string, pretty format it as XML and add a trailing
        # newline to the end so we can write trailing newlines in our files/jamf
        # xml files and not have to deal with annoying diffs
        payloads: payloads ? pretty_xml(payloads) + "\n" : payloads,
        all_computers: config_profile_scope['all_computers'],
        all_jss_users: config_profile_scope['all_jss_users'],
        scoped_computers: config_profile_scope['computers'],
        scoped_computer_groups: config_profile_scope['computer_groups'],
        scoped_buildings: config_profile_scope['buildings'],
        scoped_departments: config_profile_scope['departments'],
        scoped_jss_users: config_profile_scope['jss_users'],
        scoped_jss_user_groups: config_profile_scope['jss_user_groups'],
        limited_users: config_profile_scope['limitations']['users'],
        limited_user_groups: config_profile_scope['limitations']['user_groups'],
        limited_network_segments: config_profile_scope['limitations']['network_segments'],
        limited_ibeacons: config_profile_scope['limitations']['ibeacons'],
        excluded_computers: config_profile_scope['exclusions']['computers'],
        excluded_computer_groups: config_profile_scope['exclusions']['computer_groups'],
        excluded_buildings: config_profile_scope['exclusions']['buildings'],
        excluded_departments: config_profile_scope['exclusions']['departments'],
        excluded_users: config_profile_scope['exclusions']['users'],
        excluded_user_groups: config_profile_scope['exclusions']['user_groups'],
        excluded_network_segments: config_profile_scope['exclusions']['network_segments'],
        excluded_ibeacons: config_profile_scope['exclusions']['ibeacons'],
        excluded_jss_users: config_profile_scope['exclusions']['jss_users'],
        excluded_jss_user_groups: config_profile_scope['exclusions']['jss_user_groups'],
      }
    else
      instance = {
        ensure: :absent,
        name: config_profile_name,
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
        url = computer_config_profile_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        os_x_configuration_profile: {
          general: {
            name: config_profile_name,
            description: resource[:description],
            category: {
              name: resource[:category],
            },
            distribution_method: resource[:distribution_method],
            user_removable: resource[:user_removable],
            level: resource[:level],
            redeploy_on_update: resource[:redeploy_on_update],
            payloads: resource[:payloads],
          },
          scope: {
            all_computers: resource[:all_computers],
            all_jss_users: resource[:all_jss_users],
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
            jss_users: {
              jss_user: resource[:scoped_jss_users],
            },
            jss_user_groups: {
              jss_user_group: resource[:scoped_jss_user_groups],
            },
            limitations: {
              users: {
                user: resource[:limited_users],
              },
              user_groups: {
                user_group: resource[:limited_user_groups],
              },
              network_segments: {
                network_segment: resource[:limited_network_segments],
              },
              ibeacons: {
                ibeacon: resource[:limited_ibeacons],
              },
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
              network_segments: {
                network_segment: resource[:excluded_network_segments],
              },
              ibeacons: {
                ibeacon: resource[:excluded_ibeacons],
              },
              jss_users: {
                jss_user: resource[:excluded_jss_users],
              },
              jss_user_groups: {
                jss_user_group: resource[:excluded_jss_user_groups],
              },
            },
          },
        },
      }
      # Attach UUID to template payloads for PUT requests only
      unless cached_instance[:id].nil?
        hash[:os_x_configuration_profile][:general][:payloads][:uuid] = cached_instance[:uuid]
      end
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(computer_config_profile_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(computer_config_profile_url + "/id/#{cached_instance[:id]}",
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

  def computer_config_profile_url
    # create a URL based on our API URL
    @computer_config_profile_url ||= "#{resource[:api_url]}/JSSResource/osxconfigurationprofiles"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an config_profile_name attribute for cloud
  #       server management to operate correctly.
  def config_profile_name
    resource[:is_cloud] ? resource[:config_profile_name] : resource[:name]
  end
end

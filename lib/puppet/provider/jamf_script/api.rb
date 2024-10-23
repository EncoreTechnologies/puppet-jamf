require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_script).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(script_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    scripts_list = body_json['scripts']

    # find the category that matches our name
    matches = scripts_list.select { |ls| ls['name'] == script_name }
    if matches.size >= 1
      script_id = matches.first['id']
      resp = authorized_http_client.get(script_url + "/id/#{script_id}",
                                        headers: { 'Accept' => 'application/json' })
      script = JSON.parse(resp.body)['script']
      script_contents = script['script_contents']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: script['id'],
        name: script['name'],
        category: script['category'],
        info: script['info'],
        notes: script['notes'],
        priority: script['priority'],
        os_requirements: script['os_requirements'],
        # if the script is a good string, add a trailing newline to the end
        # so we can write trailing newlines in our files
        # and maintain idempotency.
        script: script_contents ? script_contents + "\n" : script_contents,
      }
      params = [:parameter4, :parameter5, :parameter6, :parameter7, :parameter8, :parameter9,
                :parameter10, :parameter11]
      params.each do |param|
        param_s = param.to_s
        instance[param] = script['parameters'][param_s] if script['parameters'].key?(param_s)
      end
    else
      instance = {
        ensure: :absent,
        name: script_name,
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
        url = script_url + "/id/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        script: {
          name: script_name,
          category: resource[:category],
          info: resource[:info],
          notes: resource[:notes],
          priority: resource[:priority],
          parameters: {},
          os_requirements: resource[:os_requirements],
          script_contents: resource[:script],
        },
      }
      params = [:parameter4, :parameter5, :parameter6, :parameter7, :parameter8, :parameter9,
                :parameter10, :parameter11]
      params.each do |param|
        if resource[param] && resource[param] != :absent
          hash[:script][:parameters][param] = resource[param]
        end
      end
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(script_url + '/id/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(script_url + "/id/#{cached_instance[:id]}",
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

  def script_url
    # create a URL based on our API URL
    @script_url ||= "#{resource[:api_url]}/JSSResource/scripts"
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an script_name attribute for cloud
  #       server management to operate correctly.
  def script_name
    resource[:is_cloud] ? resource[:script_name] : resource[:name]
  end
end

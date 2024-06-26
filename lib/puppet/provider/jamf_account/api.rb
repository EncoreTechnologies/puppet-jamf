require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_account).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(accounts_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    accounts_list = body_json['accounts']['users']

    # find the category that matches our name
    matches = accounts_list.select { |ls| ls['name'] == account_name }
    if matches.size >= 1
      user_id = matches.first['id']
      resp = authorized_http_client.get(user_url(user_id),
                                        headers: { 'Accept' => 'application/json' })
      account = JSON.parse(resp.body)['account']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: account['id'],
        name: account['name'],
        full_name: account['full_name'],
        email: account['email'],
        email_address: account['email_address'],
        # note, we can't use password_sha256 here because the password in the
        #       JAMF database is salted, so the hash is different every time
        #       resulting in lack of idempotency when comparing string values
        #       Instead we test the password by making an API call for this user.
        #       If auth succeeds then we know our current password is the same as the one
        #       in the database, otherwise if auth fails and we know our current password is
        #       different than the one in the database and it needs updated.
        password: read_instance_password,
        enabled: account['enabled'],
        force_password_change: account['force_password_change'],
        access_level: account['access_level'],
        privilege_set: account['privilege_set'],
        jss_object_privileges: account['privileges']['jss_objects'],
        jss_settings_privileges: account['privileges']['jss_settings'],
        jss_actions_privileges: account['privileges']['jss_actions'],
      }
    else
      instance = {
        ensure: :absent,
        name: account_name,
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
    puts jamf_cookie
    case resource[:ensure]
    when :absent
      # don't delete if we can't find an instance that matches by name
      unless cached_instance[:id].nil?
        url = accounts_url + "/userid/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        account: {
          name: account_name,
          full_name: resource[:full_name],
          email: resource[:email],
          email_address: resource[:email_address],
          password: resource[:password],
          enabled: resource[:enabled],
          force_password_change: resource[:force_password_change],
          access_level: resource[:access_level],
          privilege_set: resource[:privilege_set],
          privileges: {
            jss_objects: {
              privilege: resource[:jss_object_privileges],
            },
            jss_settings: {
              privilege: resource[:jss_settings_privileges],
            },
            jss_actions: {
              privilege: resource[:jss_actions_privileges],
            },
          },
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(accounts_url + '/userid/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(accounts_url + "/userid/#{cached_instance[:id]}",
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

  def accounts_url
    # create a URL based on our API URL
    @accounts_url ||= "#{resource[:api_url]}/JSSResource/accounts"
  end

  def user_url(userid)
    accounts_url + "/userid/#{userid}"
  end

  def read_instance_password
    # try hitting the new "auth token" API with our username and password, if that works
    # then we know the password the user requested (resource[:password]) is good,
    # so return the current value of password
    # otherwise, if we get a 401 unauthorized, then we know our password is bad
    # so return a :absent so the password is updated.
    pwd_client = Puppet::X::HTTPHelper.new(username: account_name,
                                           password: resource[:password])
    pwd_client.post("#{resource[:api_url]}/api/v1/auth/token",
                    headers: { 'Accept' => 'application/json' })
    resource[:password]
  rescue Net::HTTPUnauthorized, Net::HTTPForbidden, Net::HTTPServerException => e
    raise e unless e.response.code == '401' || e.response.code == '403'
    Puppet.debug("Got response #{e.response.code} when trying to test password")
    # if we have a 401 (Unauthorized) or 403 (forbidden),
    # then the password given was bad, so return :absent
    :absent
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an account_name attribute for cloud
  #       server management to operate correctly.
  def account_name
    resource[:is_cloud] ? resource[:account_name] : resource[:name]
  end
end

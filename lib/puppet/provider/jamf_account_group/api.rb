require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_account_group).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(account_groups_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    account_groups_list = body_json['accounts']['groups']

    # find the group that matches our name
    matches = account_groups_list.select { |ls| ls['name'] == group_name }
    if matches.size >= 1
      group_id = matches.first['id']
      resp = authorized_http_client.get(group_url(group_id),
                                        headers: { 'Accept' => 'application/json' })
      group = JSON.parse(resp.body)['group']
      instance = {
        ensure: :present,
        # note, we need the ID here so we know below to add or update
        id: group['id'],
        name: group['name'],
        access_level: group['access_level'],
        privilege_set: group['privilege_set'],
        ldap_server: group['ldap_server']['name'],
        jss_object_privileges: group['privileges']['jss_objects'],
        jss_settings_privileges: group['privileges']['jss_settings'],
        jss_actions_privileges: group['privileges']['jss_actions'],
        casper_admin_privileges: group['privileges']['casper_admin'],
      }

      # We need to update the resource value because we are assigning defaults
      # if certain conditions are applied.
      resource[:jss_object_privileges] = jss_object_privilege_array
      resource[:jss_settings_privileges] = jss_setting_privilege_array
    else
      instance = {
        ensure: :absent,
        name: group_name,
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
        url = account_groups_url + "/groupid/#{cached_instance[:id]}"
        authorized_http_client.delete(url)
      end
    when :present
      # create
      hash = {
        group: {
          name: group_name,
          access_level: resource[:access_level],
          privilege_set: resource[:privilege_set],
          ldap_server: {
            id: ldap_server_id(resource[:ldap_server]),
          },
          privileges: {
            jss_objects: {
              privilege: jss_object_privilege_array,
            },
            jss_settings: {
              privilege: jss_setting_privilege_array,
            },
            jss_actions: {
              privilege: resource[:jss_actions_privileges],
            },
            casper_admin: {
              privilege: resource[:casper_admin_privileges],
            },
          },
        },
      }
      body = hash_to_xml(hash)
      if cached_instance[:id].nil?
        # target ID 0 when creating new instances and it will auto-create our ID
        authorized_http_client.post(account_groups_url + '/groupid/0',
                                    body: body,
                                    headers: { 'Content-Type' => 'application/xml' })
      else
        authorized_http_client.put(account_groups_url + "/groupid/#{cached_instance[:id]}",
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

  def account_groups_url
    # create a URL based on our API URL
    @account_groups_url ||= "#{resource[:api_url]}/JSSResource/accounts"
  end

  def group_url(groupid)
    account_groups_url + "/groupid/#{groupid}"
  end

  def ldap_servers_url
    # create a URL based on our API URL
    @ldap_servers_url ||= "#{resource[:api_url]}/JSSResource/ldapservers"
  end

  def ldap_server_id(ldap_server)
    resp = authorized_http_client.get(ldap_servers_url,
                                      headers: { 'Accept' => 'application/json' })
    body_json = JSON.parse(resp.body)
    ldap_servers_list = body_json['ldap_servers']

    # find the group that matches our name
    matches = ldap_servers_list.select { |ls| ls['name'] == ldap_server }

    return unless matches.size >= 1

    @ldap_server_id = matches.first['id']
  end

  def jss_object_privilege_array
    if resource[:jss_object_read_all]
      read_jss_objects = [
        'Read Advanced Computer Searches',
        'Read Advanced Mobile Device Searches',
        'Read Advanced User Searches',
        'Read Advanced User Content Searches',
        'Read AirPlay Permissions',
        'Read Allowed File Extension',
        'Read API Integrations',
        'Read API Roles',
        'Read Attachment Assignments',
        'Read Device Enrollment Program Instances',
        'Read Buildings',
        'Read Categories',
        'Read Classes',
        'Read Computer Enrollment Invitations',
        'Read Computer Extension Attributes',
        'Read Custom Paths',
        'Read Computer PreStage Enrollments',
        'Read Computers',
        'Read Departments',
        'Read Device Name Patterns',
        'Read Directory Bindings',
        'Read Disk Encryption Configurations',
        'Read Disk Encryption Institutional Configurations',
        'Read Dock Items',
        'Read eBooks',
        'Read Enrollment Customizations',
        'Read Enrollment Profiles',
        'Read Patch External Source',
        'Read File Attachments',
        'Read Distribution Points',
        'Read Push Certificates',
        'Read iBeacon',
        'Read Infrastructure Managers',
        'Read Inventory Preload Records',
        'Read VPP Invitations',
        'Read Jamf Connect Deployments',
        'Read Jamf Content Distribution Server Files',
        'Read Jamf Protect Deployments',
        'Read Accounts',
        'Read JSON Web Token Configuration',
        'Read Keystores',
        'Read LDAP Servers',
        'Read Licensed Software',
        'Read Mac Applications',
        'Read macOS Configuration Profiles',
        'Read Maintenance Pages',
        'Read Managed Software Updates',
        'Read Mobile Device Applications',
        'Read iOS Configuration Profiles',
        'Read Mobile Device Enrollment Invitations',
        'Read Mobile Device Extension Attributes',
        'Read Mobile Device Managed App Configurations',
        'Read Mobile Device PreStage Enrollments',
        'Read Mobile Devices',
        'Read Network Integration',
        'Read Network Segments',
        'Read Packages',
        'Read Patch Management Software Titles',
        'Read Patch Policies',
        'Read Peripheral Types',
        'Read Personal Device Configurations',
        'Read Personal Device Profiles',
        'Read Policies',
        'Read Printers',
        'Read Provisioning Profiles',
        'Read Remote Administration',
        'Read Removable MAC Address',
        'Read Restricted Software',
        'Read Scripts',
        'Read Self Service Bookmarks',
        'Read Self Service Branding Configuration',
        'Read Sites',
        'Read Smart Computer Groups',
        'Read Smart Mobile Device Groups',
        'Read Smart User Groups',
        'Read Software Update Servers',
        'Read Static Computer Groups',
        'Read Static Mobile Device Groups',
        'Read Static User Groups',
        'Read User Extension Attributes',
        'Read User',
        'Read VPP Assignment',
        'Read Volume Purchasing Locations',
        'Read Webhooks',
      ]
      @jss_object_privilege_array = read_jss_objects.concat(resource[:jss_object_privileges])
    else
      @jss_object_privilege_array = resource[:jss_object_privileges]
    end
  end

  def jss_setting_privilege_array
    if resource[:jss_setting_read_all]
      read_jss_settings = [
        'Read Activation Code',
        'Read Apache Tomcat Settings',
        'Read Apple Configurator Enrollment',
        'Read Education Settings',
        'Read Mobile Device App Maintenance Settings',
        'Read Automatic Mac App Updates Settings',
        'Read Automatically Renew MDM Profile Settings',
        'Read Cache',
        'Read Change Management',
        'Read Computer Check-In',
        'Read Cloud Distribution Point',
        'Read Cloud Services Settings',
        'Read Clustering',
        'Read Computer Check-In',
        'Read Computer Inventory Collection',
        'Read Computer Inventory Collection Settings',
        'Read Conditional Access',
        'Read Device Compliance Information',
        'Read Engage Settings',
        'Read GSX Connection',
        'Read Patch Internal Source',
        'Read Jamf Connect Settings',
        'Read Parent App Settings',
        'Read Jamf Protect Settings',
        'Read JSS URL',
        'Read Teacher App Settings',
        'Read Limited Access Settings',
        'Read Retention Policy',
        'Read Mobile Device Inventory Collection',
        'Read Onboarding Configuration',
        'Read Password Policy',
        'Read Patch Management Settings',
        'Read PKI',
        'Read Re-enrollment',
        'Read Computer Security',
        'Read Self Service',
        'Read App Request Settings',
        'Read Mobile Device Self Service',
        'Read SMTP Server',
        'Read SSO Settings',
        'Read User-Initiated Enrollment',
      ]
      @jss_setting_privilege_array = read_jss_settings.concat(resource[:jss_settings_privileges])
    else
      @jss_setting_privilege_array = resource[:jss_settings_privileges]
    end
  end

  # NOTE: resource[:is_cloud] is defaulted to false and resource[:name] is the default
  #       value for internal jamf servers. we must pass in the is_cloud attribute
  #       with a value of true along with an group_name attribute for cloud
  #       server management to operate correctly.
  def group_name
    resource[:is_cloud] ? resource[:group_name] : resource[:name]
  end
end

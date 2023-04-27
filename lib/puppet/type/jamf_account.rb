require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_account) do
  desc "Manages a JAMF cloud server's accounts"

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the account for internal servers.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:full_name) do
    desc "Name of the account holder (e.g. 'John Smith')."

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Full Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:email) do
    desc "Email address for the account (e.g. 'john@mycompany.com')."

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Email is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:email_address) do
    desc "Email address for the account (e.g. 'john@mycompany.com')."

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Email is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if value != @resource[:email]
        @resource[:email]
      else
        value
      end
    end
  end

  newproperty(:password) do
    desc 'Password for Jamf Pro server user account.'
    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:enabled) do
    desc "Access status of the account ('Enabled' or 'Disabled')."
    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Enabled is expected to be a String, given: #{value.class.name}"
      end
      allowed_values = ['Enabled', 'Disabled']
      unless allowed_values.include?(value)
        raise ArgumentError, "Enabled needs to be one of #{allowed_values}, instead you gave me: #{value['enabled']}"
      end
    end
  end

  newproperty(:force_password_change, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Force user to change password at next login.'

    isrequired

    defaultto false
  end

  newproperty(:access_level) do
    desc 'Level of access to grant the account.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Access Level is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['Full Access', 'Site Access', 'Group Access']
      unless allowed_values.include?(value)
        raise ArgumentError, "Access Level needs to be one of #{allowed_values}, instead you gave me: #{value['access_level']}"
      end
    end
  end

  newproperty(:privilege_set) do
    desc 'Set of privileges to grant the account.'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Privilege Set is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['Administrator', 'Auditor', 'Enrollment Only', 'Custom']
      unless allowed_values.include?(value)
        raise ArgumentError, "Access Level needs to be one of #{allowed_values}, instead you gave me: #{value['privilege_set']}"
      end
    end
  end

  newproperty(:jss_object_privileges, array_matching: :all) do
    desc 'An array of JSS Object Privileges for the account.'

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(String)
        raise ArgumentError, "JSS Object Privileges are expected to be a String, given: #{value.class.name}"
      end
    end

    def sort_array(a)
      if a.nil?
        []
      else
        a.sort
      end
    end

    def should
      sort_array(super)
    end

    def should=(values)
      super(sort_array(values))
    end

    def insync?(is)
      sort_array(is) == should
    end
  end

  newproperty(:jss_settings_privileges, array_matching: :all) do
    desc 'An array of JSS Settings Privileges for the account.'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(String)
        raise ArgumentError, "JSS Settings Privileges are expected to be a String, given: #{value.class.name}"
      end
    end

    def sort_array(a)
      if a.nil?
        []
      else
        a.sort
      end
    end

    def should
      sort_array(super)
    end

    def should=(values)
      super(sort_array(values))
    end

    def insync?(is)
      sort_array(is) == should
    end
  end

  newproperty(:jss_actions_privileges, array_matching: :all) do
    desc 'An array of JSS Actions Privileges for the account.'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(String)
        raise ArgumentError, "JSS Actions Privileges are expected to be a String, given: #{value.class.name}"
      end
    end

    def sort_array(a)
      if a.nil?
        []
      else
        a.sort
      end
    end

    def should
      sort_array(super)
    end

    def should=(values)
      super(sort_array(values))
    end

    def insync?(is)
      sort_array(is) == should
    end
  end

  newproperty(:casper_admin_privileges, array_matching: :all) do
    desc 'An array of Casper Admin Privileges for the account.'

    defaultto []

    validate do |value|
      # note: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(String)
        raise ArgumentError, "Casper Admin Privileges are expected to be a String, given: #{value.class.name}"
      end
    end

    def sort_array(a)
      if a.nil?
        []
      else
        a.sort
      end
    end

    def should
      sort_array(super)
    end

    def should=(values)
      super(sort_array(values))
    end

    def insync?(is)
      sort_array(is) == should
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be 'measured' or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/accounts' to the end of this. Default: https://127.0.0.1:8443"

    isrequired

    defaultto 'https://127.0.0.1:8443'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_url is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_username) do
    desc 'Username for authentication to the API.'

    isrequired

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_username is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:api_password) do
    desc 'Password for authentication to the API.'

    isrequired

    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "api_password is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:account_name) do
    desc 'Name of the account for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Account Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:is_cloud, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Check is server is cloud or internal'

    isrequired

    defaultto false
  end

  newparam(:auth_token) do
    desc 'Token used for authentication to the API.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "auth_token is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:jamf_cookie) do
    desc 'Cookie used to avoid cluster refresh issues with cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "jamf_cookie is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newparam(:conn_validator) do
    desc 'Title of the jamf_conn_validator resource to auto-require'

    defaultto 'jamf'
  end

  autorequire(:jamf_conn_validator) do
    @parameters[:conn_validator]
  end
end

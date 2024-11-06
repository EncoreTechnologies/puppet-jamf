require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_reenrollment) do
  desc "Manages a JAMF server's re-enrollment settings"

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc "Name of the organization we're managing."

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:flush_location_information, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Clears computer and mobile device information from the User and Location category on the Inventory tab in inventory information during re-enrollment'

    isrequired

    defaultto true
  end

  newproperty(:flush_location_information_history, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Clears computer and mobile device information from the User and Location History category on the History tab in inventory information during re-enrollment'

    isrequired

    defaultto true
  end

  newproperty(:flush_policy_logs, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Clears the logs for policies that ran on the computer and clears computer information from the Policy Logs category on the History tab in inventory information during re-enrollment'

    isrequired

    defaultto true
  end

  newproperty(:flush_extension_attributes, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Clears all values for extension attributes from computer and mobile device inventory information
         during re-enrollment. This does not apply to extension attributes populated by scripts or LDAP Attribute Mapping'

    isrequired

    defaultto true
  end

  newproperty(:flush_software_update_plans, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Clears all values for software update plans from computer and mobile device inventory information during re-enrollment'

    isrequired

    defaultto true
  end

  newproperty(:flush_mdm_queue) do
    desc 'Clears computer and mobile device information from the Management History category on the History tab in inventory information during re-enrollment'

    isrequired

    defaultto 'DELETE_EVERYTHING'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Flush MDM Queue value is expected to be a String, given: #{value.class.name}"
      end

      allowed_values = ['DELETE_NOTHING', 'DELETE_ERRORS', 'DELETE_EVERYTHING_EXCEPT_ACKNOWLEDGED', 'DELETE_EVERYTHING']
      unless allowed_values.include?(value)
        raise ArgumentError, "Flush MDM Queue value needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be 'measured' or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/api/v1/reenrollment' to the end of this. Default: https://127.0.0.1:8443"

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

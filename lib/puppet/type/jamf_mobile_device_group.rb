require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_mobile_device_group) do
  desc 'Manages Mobile Device Groups within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Mobile Device Group'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:is_smart, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether this Mobile Device Group is smart or static.'

    isrequired

    defaultto true
  end

  newproperty(:criteria, array_matching: :all) do
    desc 'The criteria devices must meet to be included within the search'

    isrequired

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Criteria is expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Criterion required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Criterion 'name' value expected to be String, given: #{value['name'].class.name}"
      end

      unless value.key?('priority')
        raise ArgumentError, "Criterion required to have a 'priority' key, given: #{value}"
      end
      unless value['priority'].is_a?(Integer)
        raise ArgumentError, "Criterion 'priority' value expected to be an Integer, given: #{value['priority'].class.name}"
      end

      unless value.key?('and_or')
        raise ArgumentError, "Criterion required to have a 'and_or' key, given: #{value}"
      end
      unless value['and_or'].is_a?(String)
        raise ArgumentError, "Criterion 'and_or' value expected to be an String, given: #{value['and_or'].class.name}"
      end
      allowed_values = ['and', 'or']
      unless allowed_values.include?(value['and_or'])
        raise ArgumentError, "And_Or needs to be one of #{allowed_values}, instead you gave me: #{value['and_or']}"
      end

      unless value.key?('search_type')
        raise ArgumentError, "Criterion required to have a 'search_type' key, given: #{value}"
      end
      unless value['search_type'].is_a?(String)
        raise ArgumentError, "Criterion 'search_type' value expected to be a String, given: #{value['search_type'].class.name}"
      end

      unless value.key?('value')
        raise ArgumentError, "Criterion required to have a 'value' key, given: #{value}"
      end

      unless value.key?('opening_paren')
        raise ArgumentError, "Criterion required to have a 'opening_paren' key, given: #{value}"
      end
      unless [true, false].include?(value['opening_paren'])
        raise ArgumentError, "Criterion 'opening_paren' value expected to be a Boolean, given: #{value['opening_paren'].class.name}"
      end

      unless value.key?('closing_paren')
        raise ArgumentError, "Criterion required to have a 'closing_paren' key, given: #{value}"
      end
      unless [true, false].include?(value['closing_paren'])
        raise ArgumentError, "Criterion 'closing_paren' value expected to be a Boolean, given: #{value['closing_paren'].class.name}"
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc 'URL of the JAMF API. Note: we will append "/JSSResource/mobiledevicegroups" to the end of this. Default: https://127.0.0.1:8443'

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

  newparam(:group_name) do
    desc 'Name of the Mobile Device Group for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "group_name is expected to be a String, given: #{value.class.name}"
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

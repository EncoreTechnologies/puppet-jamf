require 'puppet/property/boolean'

Puppet::Type.newtype(:jamf_restricted_software) do
  desc 'Manages Restricted Software Records within a Jamf Pro Server'

  ensurable

  # namevar is always a parameter
  newparam(:name, namevar: true) do
    desc 'Name of the Restricted Software Record'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:process_name) do
    desc "Name of the process to restrict (e.g., 'Chess', or 'Chess.app'). The asterisk (*) can be used as a wildcard character"

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Process Name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:match_exact_process_name, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Only restrict processes that match the exact process name. The match is case-sensitive and recognizes the asterisk (*) as a literal character'

    defaultto false
  end

  newproperty(:send_notification, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'When the process is found, send an email notification to Jamf Pro users with email notifications enabled. An SMTP server must be set up in Jamf Pro for this to work'

    defaultto false
  end

  newproperty(:kill_process, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Terminate the process when found'

    defaultto true
  end

  newproperty(:delete_executable, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Delete the application running the restricted process'

    defaultto false
  end

  newproperty(:display_message) do
    desc 'Message to display to users when the process is found'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Display Message is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:all_computers, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to restrict the software on all computers'

    defaultto false
  end

  newproperty(:scoped_computers, array_matching: :all) do
    desc 'Computers on which to restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Computers are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Computers required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Computers 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_computers(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_computers(super)
    end

    def should=(values)
      super(sort_computers(values))
    end

    def insync?(is)
      sort_computers(is) == should
    end
  end

  newproperty(:scoped_computer_groups, array_matching: :all) do
    desc 'Computer Groups on which to restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Computer Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Computer Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Computer Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_groups(super)
    end

    def should=(values)
      super(sort_groups(values))
    end

    def insync?(is)
      sort_groups(is) == should
    end
  end

  newproperty(:scoped_buildings, array_matching: :all) do
    desc 'Buildings on which to restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Buildings are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Buildings required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Buildings 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_buildings(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_buildings(super)
    end

    def should=(values)
      super(sort_buildings(values))
    end

    def insync?(is)
      sort_buildings(is) == should
    end
  end

  newproperty(:scoped_departments, array_matching: :all) do
    desc 'Departments on which to restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Scoped Departments are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Scoped Departments required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Scoped Departments 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_departments(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_departments(super)
    end

    def should=(values)
      super(sort_departments(values))
    end

    def insync?(is)
      sort_departments(is) == should
    end
  end

  newproperty(:excluded_computers, array_matching: :all) do
    desc 'Computers on which to not restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Computers are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Computers required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Computers 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_computers(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_computers(super)
    end

    def should=(values)
      super(sort_computers(values))
    end

    def insync?(is)
      sort_computers(is) == should
    end
  end

  newproperty(:excluded_computer_groups, array_matching: :all) do
    desc 'Computer Groups on which to not restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Computer Groups are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Computer Groups required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Computer Groups 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_groups(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_groups(super)
    end

    def should=(values)
      super(sort_groups(values))
    end

    def insync?(is)
      sort_groups(is) == should
    end
  end

  newproperty(:excluded_buildings, array_matching: :all) do
    desc 'Buildings on which to not restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Buildings are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Buildings required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Buildings 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_buildings(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_buildings(super)
    end

    def should=(values)
      super(sort_buildings(values))
    end

    def insync?(is)
      sort_buildings(is) == should
    end
  end

  newproperty(:excluded_departments, array_matching: :all) do
    desc 'Departments on which to not restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Departments are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Departments required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Departments 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_departments(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_departments(super)
    end

    def should=(values)
      super(sort_departments(values))
    end

    def insync?(is)
      sort_departments(is) == should
    end
  end

  newproperty(:excluded_users, array_matching: :all) do
    desc 'Users for which to not restrict the software'

    defaultto []

    validate do |value|
      # NOTE: Puppet automatically detects if the value is an array and calls this validate()
      #       on each item/value within the array
      unless value.is_a?(Hash)
        raise ArgumentError, "Excluded Users are expected to be a Hash, given: #{value.class.name}"
      end

      unless value.key?('name')
        raise ArgumentError, "Excluded Users required to have a 'name' key, given: #{value}"
      end
      unless value['name'].is_a?(String)
        raise ArgumentError, "Excluded Users 'name' value expected to be String, given: #{value['name'].class.name}"
      end
    end

    def sort_users(a)
      if a.nil?
        []
      else
        allowed_fields = ['name']
        b = a.map { |i| i.select { |key, _value| allowed_fields.include?(key) } }
        b.sort_by { |i| i['name'] }
      end
    end

    def should
      sort_users(super)
    end

    def should=(values)
      super(sort_users(values))
    end

    def insync?(is)
      sort_users(is) == should
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/restrictedsoftware' to the end of this. Default: https://127.0.0.1:8443"

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

  newparam(:restricted_software_name) do
    desc 'Name of the Restricted Software for cloud servers.'

    isrequired

    defaultto ''

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "restricted_software_name is expected to be a String, given: #{value.class.name}"
      end
    end
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

require 'puppet/property/boolean'
require 'puppet/util/checksums'

Puppet::Type.newtype(:jamf_smtp_server) do
  desc 'Manages the SMTP server used to send email alerts in a Jamf Pro server'

  ensurable

  # namevar is always a parameter
  ### NOTE
  # This param is not currently being used
  # If you want to use this param you must consider that it will
  # return different values depending on the type of server
  # (internal or cloud).
  newparam(:name, namevar: true) do
    desc 'Name of the Category'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "name is expected to be a String, given: #{value.class.name}"
      end
    end
  end

  newproperty(:enabled, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether to integrate with an SMTP server to use for email communications'

    isrequired

    defaultto false
  end

  newproperty(:host) do
    desc 'Hostname or IP address of the SMTP server'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Host is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:enabled] == false
        ''
      else
        value
      end
    end
  end

  newproperty(:port) do
    desc 'Port number of the SMTP server'

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, 'Port is expected to be an Integer, given: #{value.class.name}'
      end
    end

    munge do |value|
      if @resource[:enabled] == false
        @resource[:port]
      else
        value
      end
    end
  end

  newproperty(:timeout) do
    desc 'Amount of time in seconds to wait before canceling an attempt to connect to the SMTP server'

    defaultto 10

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Timeout is expected to be an Integer, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:enabled] == false
        @resource[:timeout]
      else
        value
      end
    end
  end

  newproperty(:authorization_required, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Does the SMTP server require authentication using credentials for an SMTP account'

    defaultto false

    def should
      if @resource[:enabled] == false
        false
      else
        super()
      end
    end
  
    def insync?(is)
      if @resource[:enabled] == false
        is == false
      else
        super(is)
      end
    end
  end

  newproperty(:username) do
    desc 'The username for authentication to the SMTP server'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Username is expected to be an Integer, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:authorization_required] == false
        ''
      else
        value
      end
    end
  end

  newparam(:password) do
    desc 'Password for SMTP server user account.'
    sensitive true

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Password is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:authorization_required] == false
        ''
      else
        value
      end
    end
  end

  newproperty(:encryption) do
    desc 'Protocol to use for data encryption. 0 is no encryption, 1 is SSL, 2 is TLSv1.2, 3 is TLSv1.1, 4 is TLSv1'

    validate do |value|
      unless value.is_a?(Integer)
        raise ArgumentError, "Encryption is expected to be an Integer, given: #{value.class.name}"
      end

      allowed_values = [0, 1, 2, 3, 4]
      unless allowed_values.include?(value)
        raise ArgumentError, "Encryption needs to be one of #{allowed_values}, instead you gave me: #{value}"
      end
    end

    munge do |value|
      if @resource[:enabled] == false
        0
      else
        value
      end
    end
  end

  newproperty(:ssl, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether SSL will be used to connect to the SMTP server'

    munge do |value|
      if @resource[:encryption] != 1
        false
      else
        value
      end
    end
  end

  newproperty(:tls, boolean: true, parent: Puppet::Property::Boolean) do
    desc 'Whether TLS will be used to connect to the SMTP server'

    munge do |value|
      allowed_values = [2, 3, 4]
      if allowed_values.include?(@resource[:encryption])
        value
      else
        false
      end
    end
  end

  newproperty(:send_from_name) do
    desc 'Sender name to display in email messages sent from Jamf Pro'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Sender Name is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:enabled] == false
        ''
      else
        value
      end
    end
  end

  newproperty(:send_from_email) do
    desc 'SMTP account email address that Jamf Pro will send emails from'

    validate do |value|
      unless value.is_a?(String)
        raise ArgumentError, "Sender Email is expected to be a String, given: #{value.class.name}"
      end
    end

    munge do |value|
      if @resource[:enabled] == false
        ''
      else
        value
      end
    end
  end

  # the following are parameters because they determine how we manage the resource
  # and can not be "measured" or returned from the target system
  newparam(:api_url) do
    desc "URL of the JAMF API. Note: we will append '/JSSResource/smtpserver' to the end of this. Default: https://127.0.0.1:8443"

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

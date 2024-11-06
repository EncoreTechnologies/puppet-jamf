require File.expand_path(File.join(File.dirname(__FILE__), '..', 'jamf'))
require 'puppet/x/http_helper'

Puppet::Type.type(:jamf_reenrollment).provide(:api, parent: Puppet::Provider::Jamf) do
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
    resp = authorized_http_client.get(reenrollment_url,
                                      headers: { 'Accept' => 'application/json' })
    data = JSON.parse(resp.body)
    {
      ensure: :present,
      flush_location_information: data['isFlushLocationInformationEnabled'],
      flush_location_information_history: data['isFlushLocationInformationHistoryEnabled'],
      flush_policy_logs: data['isFlushPolicyHistoryEnabled'],
      flush_extension_attributes: data['isFlushExtensionAttributesEnabled'],
      flush_software_update_plans: data['isFlushSoftwareUpdatePlansEnabled'],
      flush_mdm_queue: data['flushMDMQueue'],
    }
  end

  # this method should check resource[:ensure]
  #  if it is :present this method should create/update the instance using the values
  #  in resource[:xxx] (these are the desired state values)
  #  else if it is :absent this method should delete the instance
  #
  #  if you want to have access to the values before they were changed you can use
  #  cached_instance[:xxx] to compare against (that's why it exists)
  def flush_instance
    return unless resource[:ensure] == :present
    # create
    hash = {
      isFlushLocationInformationEnabled: resource[:flush_location_information],
      isFlushLocationInformationHistoryEnabled: resource[:flush_location_information_history],
      isFlushPolicyHistoryEnabled: resource[:flush_policy_logs],
      isFlushExtensionAttributesEnabled: resource[:flush_extension_attributes],
      isFlushSoftwareUpdatePlansEnabled: resource["flush_software_update_plans"],
      flushMDMQueue: resource[:flush_mdm_queue],
    }
    body = hash.to_json
    authorized_http_client.put(reenrollment_url,
                               body: body,
                               headers: { 'Content-Type' => 'application/json' })
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

  def reenrollment_url
    # create a URL based on our API URL
    @reenrollment_url ||= "#{resource[:api_url]}/api/v1/reenrollment"
  end
end

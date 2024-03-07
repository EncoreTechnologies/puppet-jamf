# @summary Manages tomcat service
# @api private
class jamf::tomcat (
  Optional[String] $java_opts       = $jamf::java_opts,
  Optional[String] $organization    = $jamf::organization,
  Optional[String] $activation_code = $jamf::activation_code,
  Optional[String] $username        = $jamf::username,
  Optional[String] $password        = $jamf::password,
  String           $tomcat_service  = $jamf::tomcat_service
) {
  file_line { 'java_tomcat_setenv.sh':
    path   => '/usr/local/jss/tomcat/bin/setenv.sh',
    line   => "export JAVA_OPTS=\"${java_opts}\"",
    match  => '^export JAVA_OPTS=',
    notify => Service[$tomcat_service],
  }

  service { $tomcat_service:
    ensure => running,
    enable => true,
  }

  # note: if you use the title 'jamf' here all of the resources below will be
  #       auto-required automatically, if you use a different name you can pass in
  #       the conn_validator => 'xxx' argument to each resource to specify the different
  #       title.
  jamf_conn_validator { 'jamf': }

  # restart tomcat here so the API responds post initialization
  jamf_initialize { $organization:
    ensure          => present,
    activation_code => $activation_code,
    api_username    => $username,
    api_password    => $password,
    require         => Jamf_Conn_Validator['jamf'],
    notify          => Service[$tomcat_service],
  }

  jamf_conn_validator { 'wait_for_tomcat':
    require => Jamf_initialize[$organization],
  }
}

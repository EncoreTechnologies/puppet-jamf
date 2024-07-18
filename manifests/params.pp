# @summary Default parameters for Jamf
#
# @api private
#
class jamf::params {
  # If you are running anything less than Jamf 11.3, this needs to be set to
  # 'jamf.tomcat8'
  if versioncmp($facts['jamf_version'], '3.0.0') < 0 {
    $tomcat_service = 'jamf.tomcat8'
  } else {
    $tomcat_service = 'jamf.tomcat'
  }

  if $facts['os']['family'] == 'Redhat' {
    if versioncmp($facts['os']['release']['major'], '8') == 0 {
      $default_mysql_disable = true
    } else {
      $default_mysql_disable = false
    }
  }
}

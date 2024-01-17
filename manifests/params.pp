# @summary Default parameters for Jamf
#
# @api private
#
class jamf::params {
  if $facts['os']['family'] == 'Redhat' {
    if versioncmp($facts['os']['release']['major'], '8') == 0 {
      $default_mysql_disable = true
    } else {
      $default_mysql_disable = false
    }
  }
}

# @summary
#   This module will handle configuration of Jamf servers both cloud and on-prem
#
# @param owner
#   The filesystem owner for the directory where the Jamf Pro installer
#   will live and the installer itself.
#
#   @note Used only for on-prem servers.
#   
# @param group
#   The filesystem group for the directory where the Jamf Pro installer
#   will live and the installer itself.
#
#   @note Used only for on-prem servers.
#
# @param db
#   The name to use for the Jamf database which will be created.
#
#   @note Used only for on-prem servers.
#
# @param install_dir
#   The directory in which the Jamf Pro installer will be cached.
#
#   @note Used only for on-prem servers
#
# @param installer_name
#   param description goes here.
#
#   @note Used only for on-prem servers
#
# @param installer_path
#   param description goes here.
#
#   @note Used only for on-prem servers
#
# @param java_opts
#   The Java options which will be passed to Tomcat for each launch
#
#   @note Used only for on-prem servers
#
# @param max_backup_age
#   The maximum age of files/folders which will be stored in 
#   /usr/local/jss/backups/.
#
#   @note Used only for on-prem servers. Backups are created automatically
#   during Jamf Pro upgrades and aren't cleaned up automatically.
#   Long-standing servers can generate quite a bit of cruft here.
#
# @param organization
#   The organization to which this Jamf server belongs.
#
#   @note Used as the identifying factor for many providers that don't have
#   a specific NAME parameter to key off of e.g. SMTP, Inventory Collection, etc.
#
# @param activation_code
#   The activation code for the Jamf server gathered from
#   account.jamf.com.
#
# @param username
#   The initial admin user which will be used during Setup Assistant
#   to initialize the Jamf Pro server and also for all additional API
#   calls made
#
# @param password
#   The password for the initial admin user's account which will be used
#   for all API calls.
#
# @param is_cloud
#   param description
#
# @param mysql_overrides
#   param description
#
#   @note Used only for on-prem servers
#
# @param mysql_root_pass
#   param description
#
#   @note Used only for on-prem servers
#
# @param mysql_version
#   param description
#
#   @note Used only for on-prem servers
#
# @param os_arch
#   param description
#
#   @note Used only for on-prem servers
#
# @param os_version
#   param description
#
#   @note Used only for on-prem servers
#
# @param repo_base_url
#   param description
#
#   @note Used only for on-prem servers
#
# @param repo_gpgkey
#   param description
#
#   @note Used only for on-prem servers
#
# @param default_mysql_disable
#   RHEL8 includes a MySQL module that is enabled by default. 
#   Unless this module is disabled, it masks
#   packages provided by MySQL repositories. 
#
#   @note Used only for on-prem servers
#
# @param tomcat_service
#   Starting with v11.3, the name of the Tomcat service
#   running Jamf changes. Set this variable to the correct
#   value in params.pp
#
#   @note Used only for on-prem servers
#
# @author
#   Encore Technologies
#
class jamf (
  String            $owner                                 = 'jamf',
  String            $group                                 = '0',
  Optional[Hash]    $db                                    = undef,
  String            $install_dir                           = '/opt/jamf',
  String            $installer_name                        = undef,
  String            $installer_path                        = undef,
  Optional[String]  $java_opts                             = undef,
  String            $max_backup_age                        = '+30',
  Optional[String]  $organization                          = undef,
  Optional[String]  $activation_code                       = undef,
  Optional[String]  $username                              = undef,
  Optional[String]  $password                              = undef,
  Boolean           $is_cloud                              = false,
  Optional[Hash]    $mysql_overrides                       = undef,
  Optional[String]  $mysql_root_pass                       = undef,
  Optional[String]  $mysql_version                         = undef,
  String            $os_arch                               = $facts['os']['architecture'],
  String            $os_version                            = $facts['os']['release']['major'],
  String            $repo_base_url                         = 'https://repo.mysql.com/yum',
  String            $repo_gpgkey                           = 'https://repo.mysql.com/RPM-GPG-KEY-mysql-2022',
  Boolean           $default_mysql_disable                 = $jamf::params::default_mysql_disable,
  String            $tomcat_service                        = $jamf::params::tomcat_service
) inherits jamf::params {
  unless $is_cloud {
    require jamf::on_prem
  }
}

# @summary Manages the jamf service for on premises jamf servers
# @api private
class jamf::on_prem (
  String $max_backup_age = $jamf::max_backup_age
) {
  # contain everything and then order at bottom
  contain jamf::mysql
  contain jamf::firewall
  contain jamf::install
  contain jamf::tomcat

  Class['jamf::mysql'] -> Class['jamf::firewall'] -> Class['firewalld::reload'] -> Class['jamf::install'] -> Class['jamf::tomcat']

  # Set fact for configured on prem server
  facter::fact { 'is_jamf_configured':
    value => true,
  }

  # Clean up backups
  cron { 'Cleanup Jamf Backups':
    command => "find /usr/local/jss/backups/ -mindepth 2 -maxdepth 2 -mtime ${max_backup_age} | xargs rm -rf",
    user    => 'root',
    hour    => 2,
  }
}

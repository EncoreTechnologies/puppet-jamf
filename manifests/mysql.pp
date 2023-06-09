# @summary Installs and configures mysql on target host
# @api private
class jamf::mysql (
  $db            = $jamf::db,
  $overrides     = $jamf::mysql_overrides,
  $root_pass     = $jamf::mysql_root_pass,
  $version       = $jamf::mysql_version,
  $os_arch       = $jamf::os_arch,
  $os_version    = $jamf::os_version,
  $repo_base_url = $jamf::repo_base_url,
  $repo_gpgkey   = $jamf::repo_gpgkey,
) {
  # Set final MySQL repo URL
  $mysql_repo_url = "${repo_base_url}/mysql-${version}-community/el/${os_version}/${os_arch}/"

  ## Add external repository for MySQL
  yumrepo { 'mysql':
    baseurl  => $mysql_repo_url,
    descr    => "MySQL ${version} Community Server",
    enabled  => true,
    gpgcheck => true,
    gpgkey   => $repo_gpgkey,
  }

  ## Install and configure MySQL
  class { 'mysql::client':
    package_name => 'mysql-community-client',
    require      => Yumrepo['mysql'],
  }

  class { 'mysql::server':
    package_name            => 'mysql-community-server',
    override_options        => $overrides,
    manage_config_file      => true,
    remove_default_accounts => true,
    root_password           => $root_pass,
    service_name            => 'mysqld',
    require                 => Class['mysql::client'],
  }

  ## Create jamfsoftware database
  create_resources('::mysql::db', $db, {
      require => Class['mysql::server'],
  })
}

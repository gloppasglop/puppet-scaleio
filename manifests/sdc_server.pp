# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure  = 'present',                               # present|absent - Install or remove SDC service
  $mdm_ips  = undef,                                   # string - List of MDM IPs
  $ftp     = 'ftp://QNzgdxXix:Aw3wFAwAq3@ftp.emc.com' # string - FTP with user and password
  $package_name = $::scaleio:params::sdc_package_name,
  )
{
  $ftp_split = split($ftp, '@')
  $ftp_host = $ftp_split[1]
  $ftp_proto_split = split($ftp_split[0], '://')
  $ftp_proto = $ftp_proto_split[0]
  $ftp_creds = split($ftp_proto_split[1], ':')
  notify { "FTP to use for SDC driver: ${ftp}, ${ftp_host}, ${ftp_proto}, ${ftp_creds[0]}, ${ftp_creds[1]}": }
  
  $scini_sync_conf = {
    repo_address        => "${ftp_proto}://${ftp_host}",
    repo_user           => $ftp_creds[0],
    repo_password       => $ftp_creds[1],
    local_dir           => '/bin/emc/scaleio/scini_sync/driver_cache/',
    module_sigcheck     => 1,
    emc_public_gpg_key  => '/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO',
    repo_public_rsa_key => '/bin/emc/scaleio/scini_sync/scini_repo_key.pub',
    sync_pattern        => '.*',
  }
  $scini_sync_keys = keys($scini_sync_conf)

  package { $package_name:
    ensure => $ensure,
  }
  if $ensure == 'present' {
    file { '/bin/emc/scaleio/scini_sync/RPM-GPG-KEY-ScaleIO':
      ensure => present,
      source => 'puppet:///modules/scaleio/RPM-GPG-KEY-ScaleIO',
      mode   => '0644',
      owner  => 'root',
      group  => 'root',
      require => Package[$package_name]
    } ->
    exec { 'scaleio repo public key':
      command => "ssh-keyscan ${ftp_host} | grep ssh-rsa > /bin/emc/scaleio/scini_sync/scini_repo_key.pub",
      path    => ['/bin/', '/usr/bin', '/sbin'],
      require => Package[$package_name]
    } ->
    scini_sync { $scini_sync_keys:
      config => $scini_sync_conf,
      require => Package[$package_name]
    } ->
    exec { 'scini sync and update':
      command => 'update_driver_cache.sh && verify_driver.sh',
      unless  => 'verify_driver.sh',
      path    => ['/bin/emc/scaleio/scini_sync/', '/bin/', '/usr/bin', '/sbin'],
      require => Package[$package_name]
    } ~>
    service { 'scini':
      ensure => running,
      require => Package[$package_name]
    }
  }
  if $mdm_ips {
    $ip_array = split($mdm_ips, ',')

    if $ensure == 'present' {
        add_ip { $ip_array: }
    }
    file_line { 'Set MDM IP addresses in drv_cfg.txt':
      ensure  => present,
      line    => "mdm ${mdm_ips}",
      path    => '/bin/emc/scaleio/drv_cfg.txt',
      match   => '^mdm .*',
      require => Package[$package_name],
    }
  }

  define add_ip {
    exec { "add ip ${title}":
      command  => "drv_cfg --add_mdm --ip ${title}",
      path     => '/opt/emc/scaleio/sdc/bin:/bin',
      require  => Package[$package_name],
      unless   => "drv_cfg --query_mdms | grep ${title}"
    }
  }

  define scini_sync($config) {
    file_line { "scini_sync ${title}":
      ensure  => present,
      path    => '/bin/emc/scaleio/scini_sync/driver_sync.conf',
      match   => "^${title}",
      line    => "${title}=${config[$title]}",
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}

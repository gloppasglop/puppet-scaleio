# Configure ScaleIO SDC service installation

class scaleio::sdc_server (
  $ensure  = 'present', # present|absent - Install or remove SDC service
  $mdm_ip  = undef,     # string - List of MDM IPs
  )
{
  define add_ip {
    exec { "add ip ${title}":
	    command => "drv_cfg --add_mdm --ip ${title}",
	    path => '/opt/emc/scaleio/sdc/bin:/bin',
	    require => Package['emc-scaleio-sdc'],
	    unless => "drv_cfg --query_mdms | grep ${title}"
	  } 
	}
  
  package { ['numactl', 'libaio1']:
    ensure => installed,
  } ->
  package { ['emc-scaleio-sdc']:
    ensure => $ensure,
  }
  if $mdm_ip {
    $ip_array = split($mdm_ip, ',')

    if $ensure == 'present' {
        add_ip { $ip_array: }
    }
    file_line { 'Set MDM IP addresses in drv_cfg.txt':
      ensure  => present,
      line    => "mdm ${mdm_ip}",
      path    => '/bin/emc/scaleio/drv_cfg.txt',
      match   => '^mdm .*',
      require => Package['emc-scaleio-sdc'],
    }
  }

  # TODO:
  # "absent" cleanup
  # Rename mdm_ip to mdm_ips
}

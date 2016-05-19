# Configure ScaleIO Gateway service installation

class scaleio::mdm_server (
  $ensure                   = 'present',  # present|absent - Install or remove MDM service
  $is_manager               = undef,      # 0|1 - Tiebreaker or Manager
  $master_mdm_name          = undef,      # string - Name of the master node
  $mdm_ips                  = undef,      # string - MDM IPs
  $mdm_management_ips       = undef,      # string - MDM management IPs
  $additional_packages  = $::scaleio::params::mdm_additional_packages,
  $package_name         = $::scaleio::params::mdm_package_name,
  ) inherits scaleio::params
{
  if $ensure == 'absent' {
    package { $package_name:
      ensure => 'absent',
    }
  }
  else {
    firewall { '001 Open Ports 6611 and 9011 for ScaleIO MDM':
      dport   => [6611, 9011],
      proto   => tcp,
      action  => accept,
    }
    package { $additional_packages:
      ensure => installed,
    } ->
    package { $package_name:
      ensure => $ensure,
    }
    service { ['mdm']:
      ensure    => 'running',
      enable    => true,
      hasstatus => true,
      require   => Package[$package_name],
    }

    if $is_manager != undef {
      file_line { 'mdm role':
        path    => '/opt/emc/scaleio/mdm/cfg/conf.txt',
        line    => "actor_role_is_manager=${is_manager}",
        match   => '^actor_role_is_manager',
        require => Package[$package_name],
        notify  => Service['mdm'],
        before  => [Exec['create_cluster']],
      }
    }

    # Cluster creation is here
    $opts = '--approve_certificate --accept_license --create_mdm_cluster --use_nonsecure_communication'
    $management_ip_opts = $mdm_management_ips ? {
      undef   => '',
      default => "--master_mdm_management_ip ${mdm_management_ips}"
    }
    exec { 'create_cluster':
      onlyif    => "test -n '${master_mdm_name}'",
      require   => Service['mdm'],
      # Sleep is needed here because service in role changing can be still alive and not restarted
      command   => "sleep 2 ; scli --query_cluster --approve_certificate || scli ${opts} --master_mdm_name ${master_mdm_name} --master_mdm_ip ${mdm_ips} ${management_ip_opts}",
      path      => '/bin:/usr/bin',
      tries     => 5,
      try_sleep => 5,
    }
  }

  # TODO:
  # "absent" cleanup
  # Configure ports
}

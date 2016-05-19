# Configure ScaleIO Gateway service installation

class scaleio::gateway_server (
  $ensure       = 'present',  # present|absent - Install or remove Gateway service
  $mdm_ips      = undef,      # string - List of MDM IPs
  $password     = undef,      # string - Password for Gateway
  $port         = 4443,       # int - Port for gateway
  $im_port      = 8081,       # int - Port for IM
  additional_packages = $::scaleio::params::gateway_additional_packages,
  $package_name = $::scaleio__params::gateway_package_name,
  ) inherits scaleio::params
{
  if $ensure == 'absent'
  {
    package { $package_name:
      ensure    => 'purged',
    }
  }
  else {
    Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
    firewall { '001 for ScaleIO Gateway':
      dport  => [$port, $im_port],
      proto  => tcp,
      action => accept,
    }
    package { $additional_packages:
        ensure  => installed,
    } ->
    java::oracle { 'jdk8' :
        ensure  => 'present',
        version => '8',
        java_se => 'jdk',
    } ->
    package { $package_name:
        ensure  => installed,
    } ->
    service { 'scaleio-gateway':
      ensure  => 'running',
      enable  => true,
    }

    file_line { 'Set security bypass':
      ensure  => present,
      line    => 'security.bypass_certificate_check=true',
      path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
      match   => '^security.bypass_certificate_check=',
      require => Package[$package_name],
    } ->
    file_line { 'Set gateway port':
      ensure  => present,
      line    => "ssl.port=${port}",
      path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match   => '^ssl.port=',
      require => Package[$package_name],
    } ->
    file_line { 'Set IM web-app port':
      ensure  => present,
      line    => "http.port=${im_port}",
      path    => '/opt/emc/scaleio/gateway/conf/catalina.properties',
      match   => '^http.port=',
      require => Package[$package_name],
    }
    if $mdm_ips {
      $mdm_ips_str = join(split($mdm_ips,','), ';')
      file_line { 'Set MDM IP addresses':
        ensure  => present,
        line    => "mdm.ip.addresses=${mdm_ips_str}",
        path    => '/opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties',
        match   => '^mdm.ip.addresses=.*',
        require => Package[$package_name],
      }
    }
    if $password {
      exec { 'Set gateway admin password':
        command     => "java -jar /opt/emc/scaleio/gateway/webapps/ROOT/resources/install-CLI.jar --reset_password '${password}' --config_file /opt/emc/scaleio/gateway/webapps/ROOT/WEB-INF/classes/gatewayUser.properties",
        path        => '/etc/alternatives',
        refreshonly => true,
        notify      => Service['scaleio-gateway']
      }
    }

    File_line <| |> ~> Service['scaleio-gateway']
  }

  # TODO:
  # "absent" cleanup
  # try installing java by puppet install module puppetlabs-java - problem is Java in Ubuntu 14.04 is incompatible
}

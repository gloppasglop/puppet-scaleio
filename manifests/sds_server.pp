# Configure ScaleIO SDS service installation

class scaleio::sds_server (
  $ensure = 'present',  # present|absent - Install or remove SDS service
  $package_name = $::scaleio::params::sds_package_name,
  )
{
  firewall { '001 Open Port 7072 for ScaleIO SDS':
    dport  => [7072],
    proto  => tcp,
    action => accept,
  }
  package { $package_name:
    ensure => $ensure,
  } ->
  exec { 'Apply noop IO scheduler for SSD/flash disks':
    command => 'bash -c \'for i in `lsblk -d -o ROTA,KNAME | awk "/^ *0/ {print($2)}"` ; do if [ -f /sys/block/$i/queue/scheduler ]; then echo noop > /sys/block/$i/queue/scheduler; fi; done\'',
    path    => '/bin:/usr/bin',
  } ->
  file { 'Ensure noop IO scheduler persistent':
    content => 'ACTION=="add|change", KERNEL=="[a-z]*", ATTR{queue/rotational}=="0",ATTR{queue/scheduler}="noop"',
    path    => '/etc/udev/rules.d/60-scaleio-ssd-scheduler.rules',
  }


  # TODO:
  # "absent" cleanup
}

class scaleio::params {
  case $::osfamily {
    'RedHat': {
      $common_packages = ['numactl', 'libaio' ]
      $mdm_additional_packages = ['mutt', 'python', 'python-paramiko'] 
      $mdm_package_name = 'EMC-ScaleIO-mdm'
      $gateway_package_name = 'EMC-ScaleIO-mdm'
    }
    default: {
      $common_packages = ['numactl', 'libaio1' ]
      $mdm_additional_packages = ['mutt', 'python', 'python-paramiko'] 
      $mdm_package_name = 'emc-scaleio-mdm'
      $gateway_package_name = 'emc-scaleio-mdm'
      $common_packages = ['numactl', 'libaio1' ]
    }
  }
}

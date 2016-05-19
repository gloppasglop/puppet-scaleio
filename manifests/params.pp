class mdm::params {
  case $::osfamily {
    'RedHat': {
      $mdm_additional_packages = ['numactl', 'libaio', 'mutt', 'python', 'python-paramiko'] 
      $gateway_additional_packages = ['numactl', 'libaio'] 
      $mdm_package_name = 'EMC-ScaleIO-mdm'
      $gateway_package_name = 'EMC-ScaleIO-mdm'
    }
    default: {
      $mdm_additional_packages = ['numactl', 'libaio1', 'mutt', 'python', 'python-paramiko'] 
      $gateway_additional_packages = ['numactl', 'libaio1'] 
      $mdm_package_name = 'emc-scaleio-mdm'
      $gateway_package_name = 'emc-scaleio-mdm'
    }
  }
}

# Storage Pool configuration
# requires FACTER ::mdm_ips to be set if not run from master MDM

define scaleio::storage_pool (
  $ensure                         = 'present',  # present|absent - Add or remove storage pool
  $protection_domain              = undef,      # string - Protection domain name
  $checksum_mode                  = undef,      # 'enable'|'disable'
  $rmcache_usage                  = undef,      # 'use'|'dont_use'
  $rmcache_write_handling_mode    = undef,      # 'cached'|'passthrough'
  $rebuild_mode                   = undef,      # 'enable'|'disable'
  $rebalance_mode                 = undef,      # 'enable'|'disable'
  $scanner_mode                   = '',         # 'device_only'|'data_comparison'|'disable'
  $scanner_bandwidth_limit        = undef,      # int
  $spare_percentage               = undef,      # int
  $zero_padding_policy            = undef,      # 'enable'|'disable'
  $rebalance_parallelism_limit    = undef,      # int
  )
{
  scaleio::cmd {"storage pool ${name} ${ensure}":
    action        => $ensure,
    entity        => 'storage_pool',
    value         => $name,
    scope_entity  => 'protection_domain',
    scope_value   => $protection_domain}

  set { "storage pool ${name} set_checksum_mode":
    is_defined  => $checksum_mode,
    change      => "--${checksum_mode}_checksum"}
  set { "storage pool ${name} set_rebuild_mode":
    is_defined  => $rebuild_mode,
    change      => "--${rebuild_mode}_rebuild --i_am_sure"}
  set { "storage pool ${name} set_rebalance_mode":
    is_defined  => $rebalance_mode,
    change      => "--${rebalance_mode}_rebalance --i_am_sure"}
  set { "storage pool ${name} modify_zero_padding_policy":
    is_defined  => $zero_padding_policy,
    change      => "--${zero_padding_policy}_zero_padding"}
  set { "storage pool ${name} set_rmcache_write_handling_mode":
    is_defined  => $rmcache_write_handling_mode,
    change      => "--rmcache_write_handling_mode ${rmcache_write_handling_mode} --i_am_sure"}
  set { "storage pool ${name} set_rmcache_usage":
    is_defined  => $rmcache_usage,
    change      => "--${rmcache_usage}_rmcache --i_am_sure"}
  set { "storage pool ${name} modify_spare_policy":
    is_defined  => $spare_percentage,
    change      => "--spare_percentage ${spare_percentage} --i_am_sure"}
  set { "storage pool ${name} set_rebuild_rebalance_parallelism":
    is_defined  => $rebalance_parallelism_limit,
    change      => "--limit ${rebalance_parallelism_limit}"}
  $scanner_mode_change = $scanner_mode ? {
    'disable'   => "--scanner_mode ${scanner_mode} --scanner_bandwidth_limit ${scanner_bandwidth_limit}",
    default     => ' '}
  set { "storage pool ${name} ${scanner_mode}_background_device_scanner":
    is_defined  => $scanner_mode != '',
    change      => $scanner_mode_change }

  # TODO:
  # Rebuild and rebalance policy should be done in separate manifest - too many options and values
}

define scaleio::set($is_defined, $change = ' ')
{
  if $is_defined {
    scaleio::cmd {$title:
      action        => $title,
      ref           => 'storage_pool_name',
      value         => $scaleio::storage_pool::name,
      scope_entity  => 'protection_domain',
      scope_value   => $scaleio::storage_pool::protection_domain,
      extra_opts    => $change
    }
  }
}


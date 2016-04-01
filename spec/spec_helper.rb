require 'rubygems'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'

#require 'puppet-openstack_spec_helper/defaults'
require 'rspec-puppet'
require 'rspec-puppet-facts'
require 'rspec/core/rake_task'
include RspecPuppetFacts

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = './spec/classes/*_spec.rb'
  t.pattern = './spec/defines/*_spec.rb'
end

RSpec.configure do |c|

  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'

end

at_exit { RSpec::Puppet::Coverage.report! }

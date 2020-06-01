$:.unshift File.expand_path("../../lib", __FILE__)
require "chef"
require "chef/knife"
require "chef/knife/cloud/google_service_helpers"

class Tester
  def config
    @config ||= {}
  end

  include Chef::Knife::Cloud::GoogleServiceHelpers
end

class UnexpectedSystemExit < RuntimeError
  def self.from(system_exit)
    new(system_exit.message).tap { |e| e.set_backtrace(system_exit.backtrace) }
  end
end

RSpec.configure do |c|
  c.raise_on_warning = true
  c.raise_errors_for_deprecations!
  c.filter_run_excluding exclude: true
  c.before(:each) do
    Chef::Config.reset
    Chef::Config[:knife] = {}
  end

  c.around(:example) do |ex|
    begin
      ex.run
    rescue SystemExit => e
      raise UnexpectedSystemExit.from(e)
    end
  end
end

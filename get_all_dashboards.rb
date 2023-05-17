# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'dogapi'
require 'json'
require 'parallel'
require_relative "datadog_dashboard_helper"

Dotenv.load

begin
  if !File.exists?("./dashboards")
    Dir.mkdir("./dashboards")
  end
  current_timestamp = Time.now.to_i
  result = DatadogDashboardHelper.get_all_dashboards
  Parallel.map(result["dashboards"], in_processes: 8) do |dashboard|
    pp dashboard['id']
    DatadogDashboardHelper.save_dashboard_locally(dashboard['id'], current_timestamp)
  end
rescue StandardError => e
  puts "Error encountered: #{e}"
  puts "Error backtrace: #{e.backtrace}"
end

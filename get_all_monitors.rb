# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'dogapi'
require 'json'
require 'parallel'
require_relative "datadog_monitor_helper"

Dotenv.load

begin
  if !File.exists?("./monitors")
    Dir.mkdir("./monitors")
  end

  page = -1
  current_timestamp = Time.now.to_i
  while (true)
    page = page + 1
    result = DatadogMonitorHelper.get_monitors(page, 200)
    if (result["monitors"].empty?)
      break
    end
    Parallel.map(result["monitors"], in_processes: 8) do |monitor|
      pp monitor['id']
      DatadogMonitorHelper.save_monitor_locally(monitor['id'], current_timestamp)
    end
  end
rescue StandardError => e
  puts "Error encountered: #{e}"
  puts "Error backtrace: #{e.backtrace}"
end

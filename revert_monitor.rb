# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'dogapi'
require 'json'
require 'tty-prompt'
require 'diffy'
require_relative "datadog_monitor_helper"

Dotenv.load

begin
  prompt = TTY::Prompt.new
  if !File.exists?("./monitors")
    Dir.mkdir("./monitors")
  end

  monitor_id = prompt.ask("Please enter the monitor id:")
  current_monitor = DatadogMonitorHelper.get_current_monitor_from_datadog(monitor_id)
  local_revisions = DatadogMonitorHelper.get_local_revisions_for_monitor(monitor_id)
  revision_list = []
  local_revisions.each do |revision|
    timestamp = File.basename(revision, ".json")

    revision_list << "#{timestamp} (created #{Time.at(timestamp.to_i)})"
  end
  selected_revision = prompt.enum_select("Select revision", revision_list)
  selected_revision_file_path = "./monitors/#{monitor_id}/#{selected_revision.split[0]}.json"
  latest_file_data = File.read(selected_revision_file_path) + "\n"
  current_monitor_data = JSON.pretty_generate(current_monitor) + "\n"
  difference = Diffy::Diff.new(current_monitor_data, latest_file_data)
  puts "Below are the differences between what is on current (denoted with a '-') followed by what it will be replaced by from the file (denoted by '+')"
  puts difference
  do_not_change = prompt.no?("Do you wish to update the monitor on datadog with the data from the selected date?")
  if (do_not_change)
    puts "Change not done on datadog"
  else
    latest_file_json = JSON.parse(latest_file_data)
    DatadogMonitorHelper.save_local_monitor_to_datadog(monitor_id, latest_file_json)
    DatadogMonitorHelper.save_monitor_locally(monitor_id, Time.now.to_i)
    puts "Data updated for monitor #{monitor_id}"
  end

rescue StandardError => e
  puts "Error encountered: #{e}"
  puts "Error backtrace: #{e.backtrace}"
end

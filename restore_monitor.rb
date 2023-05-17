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

  # Get list of remote monitors. No need to query for all. Just get batches of the list
  remote_monitors = []
  page = -1
  while (true)
    page = page + 1
    result = DatadogMonitorHelper.get_monitors(page, 200)
    if (result["monitors"].empty?)
      break
    end
    result["monitors"].each do |monitor|
      remote_monitors << monitor['id'].to_s
    end
  end

  # Get list of local monitors
  local_monitors_dirs = Dir.glob("./monitors/*")
  local_monitors = local_monitors_dirs.map do |local_monitor_dir|
    next File.basename(local_monitor_dir)
  end
  monitors_not_found = (local_monitors - remote_monitors).filter do |monitor|
    remote_monitor = DatadogMonitorHelper.get_current_monitor_from_datadog(monitor)
    if remote_monitor.empty?
      next true
    end
    next false
  end
  if monitors_not_found.empty?
    puts 'There are no monitors found locally that were not found on datadog'
    return
  end

  selected_monitor_id = prompt.enum_select("Select possible monitor to restore", monitors_not_found)
  local_revisions = DatadogMonitorHelper.get_local_revisions_for_monitor(selected_monitor_id)
  revision_list = []
  local_revisions.each do |revision|
    timestamp = File.basename(revision, ".json")

    revision_list << "#{timestamp} (created #{Time.at(timestamp.to_i)})"
  end
  selected_revision = prompt.enum_select("Select revision", revision_list)
  selected_revision_file_path = "./monitors/#{monitor_id}/#{selected_revision.split[0]}.json"
  latest_file_data = File.read(selected_revision_file_path) + "\n"
  puts "Below are the contents of the local revision for monitor with id #{selected_monitor_id}:"
  puts latest_file_data
  do_not_change = prompt.no?("Do you wish to recreate this monitor on datadog")
  if (do_not_change)
    puts "Local file not restored on datadog"
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

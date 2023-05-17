# frozen_string_literal: true

require 'dogapi'

class DatadogMonitorHelper
  def self.save_monitor_locally(monitor_id, timestamp)
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])
    if !File.exists?("./monitors/#{monitor_id}")
      Dir.mkdir("./monitors/#{monitor_id}")
    end
    latest_file = Dir.glob("./monitors/#{monitor_id}/*").max_by {|f| File.mtime(f)}
    status, current_monitor = dog_api_client.get_monitor(monitor_id.to_i)
    if (status == "200")
      write_to_file = true
      current_monitor_json = JSON.pretty_generate(current_monitor)
      if (latest_file)
        latest_file_data = File.read(latest_file)
        latest_file_json = JSON.parse(latest_file_data)
        if (current_monitor['modified'] == latest_file_json['modified'])
          return
        end
      end
      if (write_to_file)
        File.write("./monitors/#{monitor_id}/#{timestamp}.json", current_monitor_json)
      end
    end
  end

  def self.save_local_monitor_to_datadog(monitor_id, updated_monitor_json)
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])
    dog_api_client.update_monitor(monitor_id, nil, updated_monitor_json)
  end

  def self.get_monitors(page = 0, limit = 30)
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])

    opts = {
      page: page, # Integer | Page to start paginating from.
      per_page: limit, # Integer | Number of monitors to return per page.
    }
    *, data = dog_api_client.search_monitors(opts)
    return data
  end

  def self.get_current_monitor_from_datadog(monitor_id)
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])
    *, current_monitor = dog_api_client.get_monitor(monitor_id.to_i)
    return current_monitor
  end

  def self.get_local_revisions_for_monitor(monitor_id)
    # Make sure we have at least one monitor revision locally, even if it is just the most recent one
    self.save_monitor_locally(monitor_id, Time.now.to_i)
    files = Dir.glob("./monitors/#{monitor_id}/*.json")
    return files
  end
end

# frozen_string_literal: true

require 'dogapi'

class DatadogDashboardHelper
  def self.get_all_dashboards
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])
    *, data = dog_api_client.get_all_boards
    return data
  end
  def self.save_dashboard_locally(dashboard_id, timestamp)
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])
    if !File.exists?("./dashboards/#{dashboard_id}")
      Dir.mkdir("./dashboards/#{dashboard_id}")
    end
    latest_file = Dir.glob("./dashboards/#{dashboard_id}/*").max_by {|f| File.mtime(f)}
    status, current_dashboard = dog_api_client.get_board(dashboard_id)
    if (status == "200")
      write_to_file = true
      current_dashboard_json = JSON.pretty_generate(current_dashboard)
      if (latest_file)
        latest_file_data = File.read(latest_file)
        latest_file_json = JSON.parse(latest_file_data)
        if (current_dashboard['modified_at'] == latest_file_json['modified_at'])
          return
        end
      end
      if (write_to_file)
        File.write("./dashboards/#{dashboard_id}/#{timestamp}.json", current_dashboard_json)
      end
    end
  end
end

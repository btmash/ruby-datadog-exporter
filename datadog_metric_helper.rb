# frozen_string_literal: true

require 'dogapi'
require 'datadog_api_client'

class DatadogMetricHelper
  def self.get_all_metrics(time)
    dog_api_client = Dogapi::Client.new(ENV["DD_API_KEY"], ENV["DD_APP_KEY"])
    *, data = dog_api_client.get_active_metrics(time)
    return data
  end

  def self.get_metric_volume(metric_name)
    dog_api_client = DatadogAPIClient::V2::MetricsAPI.new
    return dog_api_client.list_volumes_by_metric_name(metric_name)
  end

  def self.check_metric_usage_from_snapshots(metric_name)
    found_in_dashboards = %x( find ./dashboards -name "*.json" | xargs grep #{metric_name} )
    found_in_monitors = %x( find ./dashboards -name "*.json" | xargs grep #{metric_name} )
    return {
      :found_in_dashboards => !found_in_dashboards.empty?,
      :found_in_monitors => !found_in_monitors.empty?
    }
  end
end

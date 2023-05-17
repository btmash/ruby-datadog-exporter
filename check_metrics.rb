# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'dotenv'
require 'dogapi'
require 'datadog_api_client'
require 'json'
require 'parallel'
require_relative "datadog_metric_helper"

Dotenv.load

begin
  time = Time.now.to_i - (3600 * 90)
  metric_data = {}
  existing_metrics = DatadogMetricHelper.get_all_metrics(time)
  filtered_end_keywords = [
    ".duration",
    ".hits",
    ".errors",
    ".min",
    ".max",
    ".count",
    ".mean",
    "_min",
    "_max",
    "_count",
    "_mean",
    ".total",
    "1",
    "2",
    "3",
    "4",
    "5",
    "6",
    "7",
    "8",
    "9",
    "0",
  ]
  filtered_start_keywords = [
    "staging_01",
    "production_01",
    "production_02",
    "production_03",
    "production_04",
    "production_05",
    "production_06",
    "eastus_production_08",
  ]
  filtered_metrics = existing_metrics["metrics"].filter do |metric_name|
    found = false
    filtered_end_keywords.each do |filtered_end_keyword|
      if metric_name.end_with?(filtered_end_keyword)
        found = true
      end
    end
    filtered_start_keywords.each do |filtered_out_keyword|
      if metric_name.start_with?(filtered_out_keyword)
        found = true
      end
    end
    next !found
  end
  Parallel.map(filtered_metrics, in_threads: 8) do |metric_name|
    metric_data[metric_name] = DatadogMetricHelper.check_metric_usage_from_snapshots(metric_name)
  end
  not_found_metrics = metric_data.filter do |metric_name, metric|
    if (metric[:found_in_dashboards] == false && metric[:found_in_monitors] == false)
      next true
    end
    next false
  end
  File.write("./unused_metrics.json", JSON.pretty_generate(not_found_metrics.keys))
rescue StandardError => e
  puts "Error encountered: #{e}"
  puts "Error backtrace: #{e.backtrace}"
end
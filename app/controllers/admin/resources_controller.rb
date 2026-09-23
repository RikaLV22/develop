module Admin
  class ResourcesController < ApplicationController
    before_action :require_admin

    def show
      prometheus = PrometheusClient.new

      render json: {
        generated_at: Time.current.iso8601,

        prometheus: {
          status: "online"
        },

        system: {
          cpu_usage_percent:
            prometheus.scalar(cpu_usage_query),

          memory_usage_percent:
            prometheus.scalar(memory_usage_query)
        },

        api_requests_per_second:
          api_requests_per_second(prometheus),

        api_average_response_ms:
          api_average_response_ms(prometheus),

        api_requests_in_progress:
          api_requests_in_progress(prometheus),

        targets:
          target_status(prometheus),

        history:
          resource_history(prometheus)
      }
    rescue PrometheusClient::Error => e
      render json: {
        generated_at: Time.current.iso8601,

        prometheus: {
          status: "offline",
          error: e.message
        }
      }, status: :service_unavailable
    end

    private

    def require_admin
      return if current_user&.admin?

      render json: {
        message: "管理者権限が必要です"
      }, status: :forbidden
    end

    def cpu_usage_query
      <<~PROMQL
        100 * (
          1 -
          avg(
            rate(
              node_cpu_seconds_total{
                job="node",
                mode="idle"
              }[1m]
            )
          )
        )
      PROMQL
    end

    def memory_usage_query
      <<~PROMQL
        100 * (
          1 -
          (
            node_memory_MemAvailable_bytes{
              job="node"
            }
            /
            node_memory_MemTotal_bytes{
              job="node"
            }
          )
        )
      PROMQL
    end

    def api_requests_per_second(prometheus)
      prometheus
        .vector(<<~PROMQL)
          sum by (feature) (
            rate(
              ruby_http_requests_total{
                job="rails"
              }[1m]
            )
          )
        PROMQL
        .filter_map do |item|
          feature = item[:metric]["feature"]

          next if feature.blank?
          next if feature == "Other"

          {
            feature: feature,
            requests_per_second: item[:value]
          }
        end
    end

    def api_average_response_ms(prometheus)
      results =
        prometheus.vector(<<~PROMQL)
          1000 * (
            sum by (feature) (
              rate(
                ruby_http_request_duration_seconds_sum{
                  job="rails"
                }[1m]
              )
            )
            /
            sum by (feature) (
              rate(
                ruby_http_request_duration_seconds_count{
                  job="rails"
                }[1m]
              )
            )
          )
        PROMQL

      results.filter_map do |item|
        feature = item[:metric]["feature"]

        next if feature.blank?
        next if feature == "Other"

        {
          feature: feature,
          response_time_ms: item[:value]
        }
      end
    end

    def api_requests_in_progress(prometheus)
      prometheus
        .vector(<<~PROMQL)
          clamp_min(
            sum by (feature) (
              ruby_kakeibo_http_requests_in_progress{
                job="rails"
              }
            ),
            0
          )
        PROMQL
        .filter_map do |item|
          feature = item[:metric]["feature"]

          next if feature.blank?
          next if feature == "Other"

          {
            feature: feature,
            requests_in_progress: item[:value]
          }
        end
    end

    def target_status(prometheus)
      prometheus
        .vector("up")
        .map do |item|
          {
            job: item[:metric]["job"],
            instance: item[:metric]["instance"],
            up: item[:value] == 1.0
          }
        end
    end

    def resource_history(prometheus)
      end_time = Time.current
      start_time = end_time - 1.hour

      {
        range: {
          start: start_time.iso8601,
          end: end_time.iso8601,
          step: "15s"
        },

        cpu: normalize_single_series(
          prometheus.matrix(
            cpu_usage_query,
            start_time: start_time,
            end_time: end_time,
            step: "15s"
          )
        ),

        memory: normalize_single_series(
          prometheus.matrix(
            memory_usage_query,
            start_time: start_time,
            end_time: end_time,
            step: "15s"
          )
        ),

        api_requests: normalize_feature_series(
          prometheus.matrix(
            api_requests_history_query,
            start_time: start_time,
            end_time: end_time,
            step: "15s"
          )
        ),

        api_response_time: normalize_feature_series(
          prometheus.matrix(
            api_response_history_query,
            start_time: start_time,
            end_time: end_time,
            step: "15s"
          )
        ),

        api_requests_5s: normalize_feature_series(
          prometheus.matrix(
            api_requests_5s_history_query,
            start_time: start_time,
            end_time: end_time,
            step: "5s"
          )
        ),

        api_in_progress: normalize_feature_series(
          prometheus.matrix(
            api_requests_in_progress_history_query,
            start_time: start_time,
            end_time: end_time,
            step: "15s"
          )
        )
      }
    end

    def api_requests_history_query
      <<~PROMQL
        sum by (feature) (
          rate(
            ruby_http_requests_total{
              job="rails"
            }[1m]
          )
        )
      PROMQL
    end

    def api_response_history_query
      <<~PROMQL
        1000 * (
          sum by (feature) (
            rate(
              ruby_http_request_duration_seconds_sum{
                job="rails"
              }[1m]
            )
          )
          /
          sum by (feature) (
            rate(
              ruby_http_request_duration_seconds_count{
                job="rails"
              }[1m]
            )
          )
        )
      PROMQL
    end

    def api_requests_5s_history_query
      <<~PROMQL
        round(
          sum by (feature) (
            increase(
              ruby_http_requests_total{
                job="rails"
              }[5s]
            )
          )
        )
      PROMQL
    end

    def api_requests_in_progress_history_query
      <<~PROMQL
        clamp_min(
          sum by (feature) (
            ruby_kakeibo_http_requests_in_progress{
              job="rails"
            }
          ),
          0
        )
      PROMQL
    end

    def normalize_single_series(series)
      item = series.first

      return [] unless item

      item[:values]
        .reject { |point| point[:value].nan? }
    end

    def normalize_feature_series(series)
      series
        .filter_map do |item|
          feature = item[:metric]["feature"]

          next if feature.blank?
          next if feature == "Other"

          {
            feature: feature,
            values: item[:values]
              .reject { |point| point[:value].nan? }
          }
        end
    end
  end
end

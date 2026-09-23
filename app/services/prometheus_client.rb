require "net/http"
require "json"
require "uri"

class PrometheusClient
  class Error < StandardError
  end

  def initialize(
    base_url: ENV.fetch(
      "PROMETHEUS_URL",
      "http://localhost:9090"
    )
  )
    @base_url = base_url.chomp("/")
  end

  def query(promql)
    uri = URI(
      "#{@base_url}/api/v1/query"
    )

    uri.query = URI.encode_www_form(
      query: promql
    )

    response =
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 2,
        read_timeout: 3
      ) do |http|
        http.get(uri.request_uri)
      end

    unless response.is_a?(Net::HTTPSuccess)
      raise Error,
        "Prometheus HTTP error: #{response.code}"
    end

    body = JSON.parse(response.body)

    unless body["status"] == "success"
      raise Error,
        body["error"].to_s.presence ||
        "Prometheus query failed"
    end

    body.dig("data", "result") || []
  rescue JSON::ParserError => e
    raise Error,
      "Prometheus returned invalid JSON: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise Error,
      "Prometheus timeout: #{e.message}"
  rescue Errno::ECONNREFUSED, SocketError => e
    raise Error,
      "Prometheus connection failed: #{e.message}"
  end

  def query_range(
    promql,
    start_time:,
    end_time:,
    step: "15s"
  )
    uri = URI(
      "#{@base_url}/api/v1/query_range"
    )

    uri.query = URI.encode_www_form(
      query: promql,
      start: format_time(start_time),
      end: format_time(end_time),
      step: step
    )

    response =
      Net::HTTP.start(
        uri.host,
        uri.port,
        use_ssl: uri.scheme == "https",
        open_timeout: 2,
        read_timeout: 5
      ) do |http|
        http.get(uri.request_uri)
      end

    unless response.is_a?(Net::HTTPSuccess)
      raise Error,
        "Prometheus HTTP error: #{response.code}"
    end

    body = JSON.parse(response.body)

    unless body["status"] == "success"
      raise Error,
        body["error"].to_s.presence ||
        "Prometheus range query failed"
    end

    body.dig("data", "result") || []
  rescue JSON::ParserError => e
    raise Error,
      "Prometheus returned invalid JSON: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise Error,
      "Prometheus timeout: #{e.message}"
  rescue Errno::ECONNREFUSED, SocketError => e
    raise Error,
      "Prometheus connection failed: #{e.message}"
  end

  def scalar(promql)
    result = query(promql)

    return nil if result.empty?

    value = result.first["value"]

    return nil unless
      value.is_a?(Array) &&
      value.length >= 2

    Float(value[1])
  rescue ArgumentError, TypeError
    nil
  end

  def vector(promql)
    query(promql).filter_map do |item|
      value = item["value"]

      next unless
        value.is_a?(Array) &&
        value.length >= 2

      {
        metric: item["metric"] || {},
        timestamp: value[0].to_f,
        value: Float(value[1])
      }
    rescue ArgumentError, TypeError
      nil
    end
  end

  def matrix(promql, start_time:, end_time:, step: "15s")
    query_range(
      promql,
      start_time: start_time,
      end_time: end_time,
      step: step
    ).filter_map do |item|
      values = item["values"]

      next unless values.is_a?(Array)

      {
        metric: item["metric"] || {},
        values: values.filter_map do |value|
          next unless
            value.is_a?(Array) &&
            value.length >= 2

          begin
            {
              timestamp: value[0].to_f,
              value: Float(value[1])
            }
          rescue ArgumentError, TypeError
            nil
          end
        end
      }
    end
  end

  private

  def format_time(value)
    case value
    when Time
      value.iso8601
    when DateTime
      value.iso8601
    else
      value.to_s
    end
  end
end

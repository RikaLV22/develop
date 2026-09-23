unless Rails.env.test?
  require "prometheus_exporter/middleware"
  require "prometheus_exporter/client"

  class KakeiboPrometheusMiddleware < PrometheusExporter::Middleware
    FEATURES = [
      "User API",
      "Organization API",
      "Organization User API",
      "Personal Transaction API",
      "Organization Transaction API",
      "Personal Account API",
      "Organization Account API",
      "Bank API",
      "AI API"
    ].freeze

    class << self
      def requests_in_progress
        @requests_in_progress ||= PrometheusExporter::Client.default.register(
          :gauge,
          "kakeibo_http_requests_in_progress",
          "Current HTTP requests in progress"
        )
      end
    end

    def initialize(app)
      super

      FEATURES.each do |feature|
        self.class.requests_in_progress.observe(
          0,
          "feature" => feature
        )
      end
    end

    def call(env)
      path = normalized_path(env)
      feature = feature_name(path)

      tracked_feature =
        FEATURES.include?(feature) ? feature : nil

      if tracked_feature
        self.class.requests_in_progress.increment(
          "feature" => tracked_feature
        )
      end

      super
    ensure
      if tracked_feature
        self.class.requests_in_progress.decrement(
          "feature" => tracked_feature
        )
      end
    end

    def custom_labels(env)
      path = normalized_path(env)

      {
        "feature" => feature_name(path)
      }
    end

    private

    def normalized_path(env)
      path =
        env["PATH_INFO"].to_s.presence ||
        env["REQUEST_URI"].to_s.split("?").first

      path = "/" if path.blank?

      path = path.sub(%r{\A/api(?=/|\z)}, "")

      path
    end

    def feature_name(path)
      return "User API" if path.match?(%r{\A/(users|me)(/|\z)})

      return "Organization User API" if path.match?(
        %r{\A/organizations/[^/]+/users(/|\z)}
      )

      return "Organization API" if path.match?(
        %r{\A/organizations(/|\z)}
      )

      return "Personal Transaction API" if path.match?(
        %r{\A/personal_transactions(/|\z)}
      )

      return "Organization Transaction API" if path.match?(
        %r{\A/organization_transactions(/|\z)}
      )

      return "Personal Account API" if path.match?(
        %r{\A/personal_accounts(/|\z)}
      )

      return "Organization Account API" if path.match?(
        %r{\A/organization_accounts(/|\z)}
      )

      return "Bank API" if path.match?(
        %r{\A/banks(/|\z)}
      )

      return "AI API" if path.match?(
        %r{\A/(chat|personal_chat)(/|\z)}
      )

      "Other"
    end
  end

  Rails.application.middleware.unshift(
    KakeiboPrometheusMiddleware
  )
end
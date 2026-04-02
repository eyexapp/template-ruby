# frozen_string_literal: true

module Middleware
  class RequestLogger
    def initialize(app)
      @app = app
      @logger = Logger.new($stdout)
      @logger.formatter = proc do |_severity, _time, _progname, msg|
        "#{msg}\n"
      end
    end

    def call(env)
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      status, headers, body = @app.call(env)
      duration = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(2)

      @logger.info "#{env['REQUEST_METHOD']} #{env['PATH_INFO']} → #{status} (#{duration}ms)"

      [status, headers, body]
    end
  end
end

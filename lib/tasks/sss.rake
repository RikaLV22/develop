require "fileutils"

desc "Start Rails server with Solid Queue"
task :ss do
  ENV["SOLID_QUEUE_IN_PUMA"] = "true"
  exec "bin/rails server"
end

desc "Start Rails server with Solid Queue, Prometheus and exporters"
task :sss do
  ENV["SOLID_QUEUE_IN_PUMA"] = "true"

  prometheus = File.expand_path(
    "~/prometheus/prometheus"
  )

  prometheus_config = File.expand_path(
    "~/prometheus/prometheus.yml"
  )

  node_exporter = File.expand_path(
    "~/node_exporter/node_exporter"
  )

  prometheus_pid = nil
  exporter_pid = nil
  node_exporter_pid = nil
  rails_pid = nil

  begin
    FileUtils.mkdir_p("log")

    prometheus_pid = Process.spawn(
      prometheus,
      "--config.file=#{prometheus_config}",
      out: "log/prometheus.log",
      err: :out
    )

    node_exporter_pid = Process.spawn(
      node_exporter,
      "--collector.filesystem.mount-points-exclude=^/(dev|proc|run/user|run/credentials/.+|sys|var/lib/docker/.+|var/lib/containers/storage/.+)($|/)",
      out: "log/node_exporter.log",
      err: :out
    )

    exporter_pid = Process.spawn(
      "bundle",
      "exec",
      "prometheus_exporter",
      out: "log/prometheus_exporter.log",
      err: :out
    )

    sleep 1

    rails_pid = Process.spawn(
      "bin/rails",
      "server"
    )

    trap("INT") do
      Process.kill("INT", rails_pid) if rails_pid
    end

    trap("TERM") do
      Process.kill("TERM", rails_pid) if rails_pid
    end

    Process.wait(rails_pid)
  ensure
    [
      prometheus_pid,
      exporter_pid,
      node_exporter_pid
    ].each do |pid|
      next unless pid

      begin
        Process.kill("TERM", pid)
      rescue Errno::ESRCH
      end
    end

    [
      prometheus_pid,
      exporter_pid,
      node_exporter_pid
    ].each do |pid|
      next unless pid

      begin
        Process.wait(pid)
      rescue Errno::ECHILD
      end
    end
  end
end
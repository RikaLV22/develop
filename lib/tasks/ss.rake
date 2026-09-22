desc "Start Rails server with Solid Queue"
task :ss do
  ENV["SOLID_QUEUE_IN_PUMA"] = "true"
  exec "bin/rails server"
end

desc "Start Grafana"
task :grafana do
  system("sudo systemctl start grafana-server")

  if $?.success?
    puts "Grafana started: http://localhost:3301"
  else
    puts "Failed to start Grafana"
  end
end

desc "Stop Grafana"
task :grafana_stop do
  system("sudo systemctl stop grafana-server")

  if $?.success?
    puts "Grafana stopped"
  else
    puts "Failed to stop Grafana"
  end
end

desc "Restart Grafana"
task :grafana_restart do
  system("sudo systemctl restart grafana-server")

  if $?.success?
    puts "Grafana restarted: http://localhost:3301"
  else
    puts "Failed to restart Grafana"
  end
end

desc "Show Grafana status"
task :grafana_status do
  system("sudo systemctl status grafana-server --no-pager")
end
namespace :server do
  desc "Run Rails server on two ports"
  task :multi => :environment do
    puts "Starting PostgreSQL Service....."

    system("sudo systemctl stop postgresql")

    system("sudo systemctl start postgresql")
    puts "PostgreSQL Live ✅ ."

    client_ip = Socket.ip_address_list
                     .select { |addr| addr.ipv4_private? && !addr.ip_address.start_with?("172.") }
                     .first&.ip_address

    if client_ip.nil?
      puts "Could not detect a valid private IP address. Please check your network."
      exit(1)
    end

    pid_path_3000 = Rails.root.join('tmp', 'pids', 'server-3000.pid')
    pid_path_3001 = Rails.root.join('tmp', 'pids', 'server-3001.pid')

    File.delete(pid_path_3000) if File.exist?(pid_path_3000)
    File.delete(pid_path_3001) if File.exist?(pid_path_3001)

    fork do
      puts "Starting Rails server on localhost:3000..."
      exec "RAILS_ENV=development rails server -b 127.0.0.1 -p 3000 --pid #{pid_path_3000}"
    end

    fork do
      puts "Starting Rails server on #{client_ip}:3001..."
      exec "RAILS_ENV=development rails server -b #{client_ip} -p 3001 --pid #{pid_path_3001}"
    end

    Thread.new do
      sleep 5 # Give the server some time to start

      uri = URI("http://#{client_ip}:3001/api/mobile/set_app_config")
      request = Net::HTTP::Put.new(uri)
      request.set_form_data({ key: 'mobile', value: "http://#{client_ip}:3001" })

      response = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        puts "Successfully set the mobile host to http://#{client_ip}:3001"
      else
        puts "Failed to set the mobile host: #{response.code} - #{response.message}"
      end
    end

    Process.waitall
  end
end

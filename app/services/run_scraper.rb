# app/services/run_scraper.rb
class RunScraper
  def self.call
    script_path = Rails.root.join('app', 'services', 'dermatologue_scrapper.py')
    
    # Command to run the Python script
    command = "python3 #{script_path}"
    
    # Execute the command
    output = `#{command}`
    
    # Check if the script ran successfully
    if $?.exitstatus == 0
      puts "Scraper executed successfully."
      puts output
    else
      puts "Scraper failed."
      puts output
    end
  end
end

require "sidekiq"
require "sidekiq-scheduler"

Sidekiq.configure_server do |config|
  config.redis = {url: "redis://localhost:6379/0"}
  config.on(:startup) do
    Sidekiq::Scheduler.reload_schedule!  # Reload cron schedule on startup
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: "redis://localhost:6379/0"}
end

# config/initializers/sidekiq_broadcast_patch.rb
# Sidekiq 6.5's Rails integration calls Logger#broadcast, removed in
# Rails 7.1+ (ActiveSupport::BroadcastLogger replaced it). Remove this
# once Sidekiq is upgraded past the point where Redis supports it.
if Rails::VERSION::STRING >= '7.1' && !ActiveSupport::Logger.method_defined?(:broadcast)
  ActiveSupport::Logger.class_eval do
    def broadcast(other)
      other
    end
  end
end
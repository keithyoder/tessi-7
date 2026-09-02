# config/initializers/sidekiq_broadcast_patch.rb
# Sidekiq 6.5's Rails integration calls the class method
# ActiveSupport::Logger.broadcast(logger), removed in Rails 7.1+.
# Restoring Rails <7.1's own implementation here.
# Remove this once Sidekiq is upgraded past the point where Redis supports it.
if Rails::VERSION::STRING >= '7.1' && !ActiveSupport::Logger.respond_to?(:broadcast)
  module ActiveSupport
    class Logger
      def self.broadcast(logger)
        Module.new do
          define_method(:add) do |*args, &block|
            logger.add(*args, &block)
            super(*args, &block)
          end

          define_method(:<<) do |x|
            logger << x
            super(x)
          end

          define_method(:close) do
            logger.close
            super()
          end

          define_method(:progname=) do |name|
            logger.progname = name
            super(name)
          end

          define_method(:formatter=) do |formatter|
            logger.formatter = formatter
            super(formatter)
          end

          define_method(:level=) do |level|
            logger.level = level
            super(level)
          end

          define_method(:local_level=) do |level|
            logger.local_level = level if logger.respond_to?(:local_level=)
            super(level) if respond_to?(:local_level=)
          end
        end
      end
    end
  end
end

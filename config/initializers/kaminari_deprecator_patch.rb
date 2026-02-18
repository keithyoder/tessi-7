# frozen_string_literal: true

Rails.application.config.to_prepare do
  next unless defined?(Kaminari) && Kaminari.respond_to?(:deprecator)

  deprecator = Kaminari.deprecator

  if deprecator.respond_to?(:warn) && deprecator.respond_to?(:notify)
    deprecator.singleton_class.class_eval do
      def warn(*args)
        notify(*args)
      end
    end
  end
end

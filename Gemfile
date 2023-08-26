source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.1.4"

gem "rails", "~> 7.0.4", ">= 7.0.4.3"

gem "sprockets-rails"
gem "puma", "~> 5.0"
gem "jsbundling-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "cssbundling-rails"
gem "jbuilder"
gem "redis", "~> 4.0"
gem "tzinfo-data", platforms: %i[ mingw mswin x64_mingw jruby ]
gem "bootsnap", require: false
gem 'barby'
gem 'bootstrap', '~> 5'
gem 'brcobranca', git: 'https://github.com/kivanio/brcobranca.git', :ref => '246c1ea'
gem 'cancancan'
gem 'capistrano', '~> 3.11'
gem 'capistrano-passenger', '~> 0.2.1'
gem 'capistrano-rails', '~> 1.4'
gem 'capistrano-rbenv', '~> 2.1', '>= 2.1.4'
gem 'chartkick'
gem 'coffee-rails'
gem 'cpf_cnpj'
gem 'devise'
gem 'extensobr'
gem 'graphql-client', git: 'https://github.com/keithyoder/graphql-client.git'
gem 'multipart-post'
gem 'fixy'
gem 'geocoder'
gem 'gerencianet'
#gem 'gerencianet', path: '../gn-api-sdk-ruby/'
gem 'httparty'
gem 'image_processing'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'kaminari'
# gem 'mtik', git: 'https://github.com/astounding/mtik.git'
gem 'mtik'
gem 'net-ping'
gem 'net-ssh'
gem 'oauth2'
gem 'popper_js'
gem 'phonelib'
gem 'prawn-rails'
gem 'prawn-svg'
gem 'pg'
gem 'qbo_api'
gem 'qrcode_pix_ruby'
gem 'rails4-autocomplete'
gem 'rails-settings-cached', '~> 2.0'
gem 'ransack'
gem 'ruby_ami'
gem 'rubyzip', require: 'zip'
gem 'rufus-scheduler'
gem 'sidekiq'
gem 'sidekiq-cron'
gem 'simple_form'
gem 'slim'
gem "slim-rails"
gem 'snmp'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

# Use Sass to process CSS
# gem "sassc-rails"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  # Speed up commands on slow machines / big apps [https://github.com/rails/spring]
  # gem "spring"
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"
  gem "webdrivers"
end

gem "dockerfile-rails", ">= 1.5", :group => :development

# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '3.3.4'

# ------------------------------------------------------------
# Core framework
# ------------------------------------------------------------
gem 'bootsnap', require: false
gem "pg", ">= 1.6", "< 2.0", force_ruby_platform: true
gem 'puma'
gem 'rails', '~> 7.2'

# ------------------------------------------------------------
# Frontend / Assets
# ------------------------------------------------------------
# gem 'bootstrap', '~> 5'
# gem 'popper_js'
gem "sassc"
gem 'slim'
gem 'slim-rails'

gem 'cssbundling-rails'
gem 'jsbundling-rails'
#gem 'sprockets-rails'
gem 'propshaft'
gem 'stimulus-rails'
gem 'turbo-rails'

# ------------------------------------------------------------
# Authentication / Authorization
# ------------------------------------------------------------
gem 'bcrypt_pbkdf', '>= 1.0', '< 2.0'
gem 'cancancan'
gem 'devise'

# ------------------------------------------------------------
# Background jobs / Scheduling
# ------------------------------------------------------------
gem 'redis', '~> 4.0'
gem 'rufus-scheduler'
gem 'sidekiq'
gem 'sidekiq-cron'

# ------------------------------------------------------------
# API / Networking / Integrations
# ------------------------------------------------------------
gem 'graphql', '< 2.1'
gem 'graphql-client', git: 'https://github.com/keithyoder/graphql-client.git'

gem 'httparty'
gem 'multipart-post'
gem 'oauth2'

gem 'net-ftp'
gem 'net-ping'
gem 'net-ssh'
gem 'snmp'

# ------------------------------------------------------------
# Brazilian ecosystem / Finance
# ------------------------------------------------------------
gem 'barby'
gem 'brcobranca', git: 'https://github.com/kivanio/brcobranca.git', ref: '246c1ea'
gem 'cpf_cnpj'
gem 'extensobr'
gem 'fixy'

gem 'nfcom', git: 'https://github.com/keithyoder/nfcom-ruby.git'
# gem 'nfcom', path: '../nfcom-ruby'

gem 'sdk_ruby_apis_efi', git: 'https://github.com/keithyoder/sdk-ruby-apis-efi.git'
# gem 'sdk_ruby_apis_efi', path: '../sdk-ruby-apis-efi/'

# ------------------------------------------------------------
# Reporting / Documents / PDFs
# ------------------------------------------------------------
gem 'prawn-qrcode'
gem 'prawn-rails'
gem 'prawn-svg'
gem 'wicked_pdf'
gem 'wkhtmltopdf-binary'

# ------------------------------------------------------------
# UI helpers / Utilities
# ------------------------------------------------------------
gem 'chartkick'
gem 'geocoder'
gem 'image_processing'
gem 'kaminari', git: 'https://github.com/keithyoder/kaminari'
gem 'phonelib'
gem 'rails-settings-cached', '~> 2.0'
gem 'ransack'
gem 'simple_form'

# ------------------------------------------------------------
# Serialization / Parsing
# ------------------------------------------------------------
gem 'jbuilder'
gem 'matrix'
gem 'nokogiri', force_ruby_platform: true
gem 'rubyzip', require: 'zip'
gem 'strscan', '~> 3.0.9'

# ------------------------------------------------------------
# Telephony / VoIP
# ------------------------------------------------------------
gem 'mtik'
gem 'ruby_ami'

# ------------------------------------------------------------
# Low-level / Compatibility
# ------------------------------------------------------------
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

# ------------------------------------------------------------
# Development & Deployment
# ------------------------------------------------------------
group :development do
  gem 'capistrano'
  gem 'capistrano-passenger'
  gem 'capistrano-rails'
  gem 'capistrano-rbenv'
  gem 'web-console'
end

# ------------------------------------------------------------
# Development & Test
# ------------------------------------------------------------
group :development, :test do
  gem 'annotate'
  gem 'dotenv-rails'

  gem 'debug', platforms: %i[mri mingw x64_mingw]

  gem 'rubocop', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-factory_bot', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  gem 'brakeman', require: false
  gem 'bundler-audit', require: false
end

# ------------------------------------------------------------
# Test only
# ------------------------------------------------------------
group :test do
  gem 'capybara'
  gem 'factory_bot_rails'
  gem 'rspec-rails'
  gem 'selenium-webdriver'
  gem 'webdrivers'
end

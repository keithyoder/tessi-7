# frozen_string_literal: true

class WelcomeController < ApplicationController
  skip_authorization_check
  def index; end
end

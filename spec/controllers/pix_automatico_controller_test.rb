# frozen_string_literal: true

require 'test_helper'

class PixAutomaticoControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get pix_automatico_index_url
    assert_response :success
  end

  test 'should get show' do
    get pix_automatico_show_url
    assert_response :success
  end

  test 'should get create' do
    get pix_automatico_create_url
    assert_response :success
  end

  test 'should get destroy' do
    get pix_automatico_destroy_url
    assert_response :success
  end
end

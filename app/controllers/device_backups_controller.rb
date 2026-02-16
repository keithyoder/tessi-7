# frozen_string_literal: true

# == Schema Information
#
# Table name: device_backups
#
#  id         :bigint           not null, primary key
#  checksum   :string           not null
#  config     :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  device_id  :bigint           not null
#
# Indexes
#
#  index_device_backups_on_device_id  (device_id)
#
# Foreign Keys
#
#  fk_rails_...  (device_id => devices.id)
#
class DeviceBackupsController < ApplicationController
  before_action :set_device
  before_action :set_backup, only: %i[show download]

  authorize_resource class: 'DeviceBackup'

  def index
    @backups = @device.backups
      .order(created_at: :desc)
      .page(params[:page])
      .per(20)
  end

  def show
    @config = @backup.config
    @config_hash = Ubiquiti::ConfigParser.to_hash(@config) if @device.is_a?(Devices::Ubiquiti)
  end

  def download
    send_data @backup.config,
              filename: "#{@device.name}-#{@backup.created_at.strftime('%Y%m%d%H%M')}.cfg",
              type: 'application/octet-stream'
  end

  private

  def set_device
    @device = Device.find(params[:device_id])
  end

  def set_backup
    @backup = @device.backups.find(params[:id])
  end
end

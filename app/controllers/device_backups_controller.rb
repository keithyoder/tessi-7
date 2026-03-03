# frozen_string_literal: true

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
    @diff     = @backup.diff_from_previous
    @previous = @backup.previous
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

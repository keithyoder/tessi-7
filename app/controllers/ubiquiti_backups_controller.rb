class UbiquitiBackupsController < ApplicationController
  load_and_authorize_resource

  before_action :set_ponto
  before_action :set_backup, only: %i[show download]

  def index
    @backups = @ponto.ubiquiti_backups
      .order(created_at: :desc)
      .page(params[:page])
      .per(20)
  end

  def show
    @config = @backup.to_hash
  end

  def download
    cfg = Ubiquiti::ConfigManager.package_for_restore(@backup.config)

    send_data cfg,
              filename: "#{@ponto.nome}-#{@backup.created_at.strftime('%Y%m%d%H%M')}.cfg",
              type: 'application/gzip'
  end

  private

  def set_ponto
    @ponto = Ponto.find(params[:ponto_id])
  end

  def set_backup
    @backup = @ponto.ubiquiti_backups.find(params[:id])
  end
end

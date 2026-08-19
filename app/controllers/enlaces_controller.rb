# frozen_string_literal: true

class EnlacesController < ApplicationController
  include TurboFrameIndex

  escopavel_por :servidor_id, :ponto_id

  authorize_resource
  before_action :set_enlace, only: %i[show edit update destroy]
  before_action :montar_enlace_novo, only: %i[new create]
  before_action :montar_extremidades, only: %i[new edit]
  before_action :set_available_devices, only: %i[new edit create update]

  def index
    consulta = Enlace.distinct

    if params[:servidor_id].present?
      consulta = consulta.joins(:extremidades).where(
        enlace_extremidades: { infraestrutura_type: 'Servidor', infraestrutura_id: params[:servidor_id] }
      )
    elsif params[:ponto_id].present?
      consulta = consulta.joins(:extremidades).where(
        enlace_extremidades: { infraestrutura_type: 'Ponto', infraestrutura_id: params[:ponto_id] }
      )
    end

    @q = consulta.ransack(params[:q])
    @q.sorts = 'created_at desc' if @q.sorts.empty?
    @search_params = params.fetch(:q, {}).permit(:tecnologia_eq).to_h

    @pagy, @enlaces = pagy(@q.result.includes(extremidades: :infraestrutura), limit: 12)
  end

  def show; end

  def new; end

  def edit; end

  def create
    @enlace.assign_attributes(enlace_params)

    if @enlace.save
      redirect_to @enlace, notice: t('.sucesso')
    else
      render :new, status: :unprocessable_content
    end
  end

  def update
    if @enlace.update(enlace_params)
      redirect_to @enlace, notice: t('.sucesso')
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @enlace.destroy
    redirect_to enlaces_url, notice: t('.sucesso')
  end

  private

  def set_enlace
    @enlace = Enlace.includes(extremidades: %i[infraestrutura device]).find(params[:id])
  end

  def montar_enlace_novo
    @enlace = Enlace.new
  end

  def montar_extremidades
    @enlace.extremidades.build(posicao: :A) if @enlace.extremidades.none?(&:posicao_A?)
    @enlace.extremidades.build(posicao: :B) if @enlace.extremidades.none?(&:posicao_B?)
  end

  def set_available_devices
    devices = Device.unlinked.order(:mac)
    ids_atuais = @enlace.extremidades.filter_map { |e| e.device&.id }
    devices = devices.or(Device.where(id: ids_atuais)) if ids_atuais.any?
    @available_devices = devices
  end

  def enlace_params
    params.require(:enlace).permit(
      :canal, :capacidade_bytes, :fibra_cor, :observacoes, :sinal_normal, :tecnologia,
      extremidades_attributes: %i[device_id id infraestrutura_id infraestrutura_type ip posicao]
    )
  end
end

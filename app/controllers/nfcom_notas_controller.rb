# frozen_string_literal: true

class NfcomNotasController < ApplicationController
  before_action :set_nfcom_nota, only: [:show]
  before_action :permit_search_params, only: [:competencia]
  load_and_authorize_resource

  # GET /nfcom_notas
  def index
    competencia_range = (12.months.ago.beginning_of_month..)

    @competencias_com_count = NfcomNota
      .where(competencia: 12.months.ago.beginning_of_month..)
      .group(:competencia)
      .order(competencia: :desc)
      .count

    # Status counts per competência
    @status_counts_by_competencia = NfcomNota
      .where(competencia: competencia_range)
      .group(:competencia, :status)
      .count

    # Total authorized value per competência
    @authorized_values_by_competencia = NfcomNota
      .where(competencia: competencia_range)
      .authorized
      .group(:competencia)
      .sum(:valor_total)
  end

  # GET /nfcom_notas/competencia/:mes
  def competencia
    @mes = params[:mes]
    @competencia = Date.parse("#{@mes}-01")

    notas_query = NfcomNota
      .includes(fatura: { contrato: :pessoa })
      .competencia(@mes)
      .order(:numero)

    @q = notas_query.ransack(params[:q])
    notas_filtradas = @q.result

    respond_to do |format|
      format.html do
        @notas = notas_filtradas.page(params[:page]).per(50)
        @total_stats = total_stats_for(notas_filtradas)
      end

      format.pdf do
        @notas = notas_filtradas
        @total_stats = total_stats_for(notas_filtradas)
        render_competencia_pdf
      end

      format.zip do
        @notas = notas_filtradas
        send_zip_xmls
      end
    end
  end

  def show
    respond_to do |format|
      format.pdf { send_danfe_pdf }
      format.xml { send_xml }
      format.html { redirect_to nfcom_nota_path(@nfcom_nota, format: :pdf) }
    end
  rescue Nfcom::Errors::XmlError => e
    handle_xml_error(e)
  rescue StandardError => e
    handle_standard_error(e)
  end

  private

  def permit_search_params
    return if params[:q].blank?

    params[:q] = params[:q].permit(
      :fatura_contrato_pessoa_nome_cont,
      :numero_eq,
      :serie_eq,
      :status_eq
    )
  end

  def total_stats_for(scope)
    NfcomNota
      .where(id: scope.select(:id))
      .group(:status)
      .count
  end

  def render_competencia_pdf
    render pdf: "nfcom_competencia_#{@mes}",
           template: 'nfcom_notas/competencia',
           layout: 'print',
           formats: [:html],
           encoding: 'UTF-8',
           zoom: 1.0,
           margin: { top: 10, bottom: 10, left: 10, right: 10 },
           page_size: 'A4',
           orientation: 'Landscape'
  end

  def send_zip_xmls
    zip_data = Nfcom::GeradorXmlZipService
      .new(@notas)
      .generate

    send_data zip_data.string,
              filename: "nfcom_competencia_#{@mes}.zip",
              type: 'application/zip',
              disposition: 'attachment'
  end

  def send_danfe_pdf
    pdf_content = Nfcom::GeradorDanfePdfService
      .new(@nfcom_nota)
      .generate

    send_data pdf_content,
              filename: "nfcom_#{@nfcom_nota.numero}_serie_#{@nfcom_nota.serie}.pdf",
              type: 'application/pdf',
              disposition: 'inline'
  end

  def send_xml
    if @nfcom_nota.xml_autorizado.present?
      send_data @nfcom_nota.xml_autorizado,
                filename: "nfcom_#{@nfcom_nota.numero}_serie_#{@nfcom_nota.serie}.xml",
                type: 'application/xml',
                disposition: 'attachment'
    else
      flash[:error] = I18n.t('nfcom_notas.errors.not_authorized')
      redirect_to fatura_path(@nfcom_nota.fatura)
    end
  end

  def handle_xml_error(error)
    flash[:error] = error.message
    redirect_to fatura_path(@nfcom_nota.fatura)
  end

  def handle_standard_error(error)
    log_error(error)
    flash[:error] = I18n.t('nfcom_notas.errors.pdf_generation_failed')
    redirect_to fatura_path(@nfcom_nota.fatura)
  end

  def log_error(error)
    Rails.logger.error("Erro ao gerar DANFE-COM: #{error.message}\n#{error.backtrace.join("\n")}")
  end

  def set_nfcom_nota
    @nfcom_nota = NfcomNota.find(params[:id])
  end
end

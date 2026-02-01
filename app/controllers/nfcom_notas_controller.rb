# frozen_string_literal: true

class NfcomNotasController < ApplicationController # rubocop:disable Metrics/ClassLength
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

      format.csv do
        @notas = notas_filtradas
        send_data generate_csv(@notas),
                  filename: "nfcom_competencia_#{@mes}.csv",
                  type: 'text/csv',
                  disposition: 'attachment'
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

  # POST /nfcom_notas/gerar_lote
  def gerar_lote # rubocop:disable Metrics/AbcSize
    authorize! :gerar_lote, NfcomNota

    data_inicio = Date.parse(params[:data_inicio])
    data_fim = Date.parse(params[:data_fim])

    if data_inicio > data_fim
      flash[:error] = I18n.t('nfcom_notas.batch.invalid_date_range')
      redirect_to nfcom_notas_path
      return
    end

    # Enqueue the job
    GerarNotasJob.perform_later(data_inicio: data_inicio, data_fim: data_fim)

    flash[:notice] = I18n.t('nfcom_notas.batch.job_enqueued',
                            inicio: I18n.l(data_inicio),
                            fim: I18n.l(data_fim))
    redirect_to nfcom_notas_path
  rescue ArgumentError
    flash[:error] = I18n.t('nfcom_notas.batch.invalid_dates')
    redirect_to nfcom_notas_path
  rescue StandardError => e
    Rails.logger.error("Erro ao enfileirar GerarNotasJob: #{e.message}")
    flash[:error] = I18n.t('nfcom_notas.batch.job_failed')
    redirect_to nfcom_notas_path
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

  def generate_csv(notas)
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << ['Série', 'Número', 'Cliente', 'Status', 'Valor Total', 'Emissão', 'Chave de Acesso']

      notas.each do |nota|
        csv << [
          nota.serie,
          nota.numero,
          nota.fatura.contrato.pessoa.nome,
          I18n.t("nfcom_nota.statuses.#{nota.status}", count: 1),
          nota.valor_total,
          nota.created_at ? I18n.l(nota.created_at.to_date) : '',
          nota.chave_acesso || ''
        ]
      end
    end
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

# frozen_string_literal: true

class ContratosController < ApplicationController
  include ActionView::Helpers::NumberHelper
  load_and_authorize_resource
  before_action :set_contrato, only: %i[show edit update destroy renovar termo update_assinatura autentique]
  layout 'print', only: [:termo]

  # GET /contratos
  # GET /contratos.json
  def index
    contrato = Contrato.includes(:pessoa, :plano)
    contrato = contrato.ativos if params.key?(:ativos)
    contrato = contrato.renovaveis if params.key?(:renovaveis)
    contrato = contrato.suspendiveis if params.key?(:suspendiveis)
    contrato = contrato.cancelaveis if params.key?(:cancelaveis)
    contrato = contrato.fisica if params.key?(:fisica)
    contrato = contrato.juridica if params.key?(:juridica)
    contrato = contrato.novos_por_mes(params[:adesao]) if params.key?(:adesao)
    contrato = contrato.sem_conexao if params.key?(:sem_conexao)

    @params = params.permit(
      :ativos, :renovaveis, :suspendiveis, :cancelaveis, :fisica, :juridica,
      :adesao, :sem_conexao
    )
    @q = contrato.ransack(params[:q])
    @q.sorts = 'pessoas.nome'
    @contratos = @q.result.page params[:page]
    respond_to do |format|
      format.html
      format.csv do
        send_data(
          @contratos.except(:limit, :offset).to_csv,
          filename: "contratos-#{Time.zone.today}.csv"
        )
      end
    end
  end

  def pendencias
    @documentos = Autentique::Client.query(
      Autentique::DocumentosComPendencia
    ).original_hash['data']['documents']['data']
  end

  def churn
    meses = Contrato
            .select("date_trunc('month', adesao) as mes, count(*) as adesoes, min(cancelamentos.quantos) as cancelamentos")
            .joins("LEFT JOIN (SELECT count(*) AS quantos, date_trunc('month', cancelamento) as mes FROM contratos WHERE cancelamento - adesao > 15 GROUP BY date_trunc('month', cancelamento)) cancelamentos ON date_trunc('month', adesao) = cancelamentos.mes")
            .group("date_trunc('month', adesao)")
            .where('adesao - cancelamento > 15 or cancelamento is null')
            .order("date_trunc('month', adesao) DESC")
    @q = meses.ransack
    @meses = @q.result.page params[:page]
  end

  def boletos
    @faturas = @contrato.faturas
                        .where(liquidacao: nil)
                        .where(vencimento: 1.day.ago..Date::Infinity.new)
                        .order(:vencimento)
    render :carne
  end

  # GET /contratos/1
  # GET /contratos/1.json
  # GET /contratos/1.pdf
  def show
    @contrato = Contrato.find(params[:id])
    @faturas = @contrato.faturas.order(parcela: :desc).page params[:page] if request.format != :pdf
    respond_to do |format|
      format.html { render :show }
    end
  end

  def termo
    respond_to do |format|
      format.html { render :termo }
      format.json { render :termo }
      format.pdf do
        render pdf: 'termo', encoding: 'UTF-8', zoom: 1.2, margin: { top: 15, bottom: 15, left: 15, right: 15 },
               page_size: 'A4'
      end
    end
  end

  # GET /contratos/new
  def new
    @contrato = Contrato.new
    @contrato.pessoa_id = params[:pessoa_id] if params.key?(:pessoa_id)
    @contrato.valor_instalacao = 0
    @contrato.parcelas_instalacao = 0
    @contrato.primeiro_vencimento = 1.month.from_now
    @contrato.dia_vencimento = Time.zone.today.day
  end

  # GET /contratos/1/edit
  def edit; end

  def renovar
    @contrato.renovar
    respond_to do |format|
      format.html { redirect_to @contrato, notice: 'Contrato renovado com sucesso.' }
    end
  end

  def update_assinatura
    respond_to do |format|
      if @contrato.update(assinatura_params)
        GerencianetClient.criar_assinatura(@contrato, params[:token])
        format.html { redirect_to @contrato, notice: 'Assinatura criada com sucesso.' }
      else
        format.html { render :assinatura }
      end
    end
  end

  # POST /contratos
  # POST /contratos.json
  def create
    @contrato = Contrato.new(contrato_params)

    respond_to do |format|
      if @contrato.save
        format.html { redirect_to @contrato, notice: 'Contrato criado com sucesso.' }
        format.json { render :show, status: :created, location: @contrato }
      else
        format.html { render :new }
        format.json { render json: @contrato.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contratos/1
  # PATCH/PUT /contratos/1.json
  def update
    respond_to do |format|
      if @contrato.update(contrato_params)
        if verificar_conexoes_planos?
          format.html { redirect_to @contrato, notice: 'Contrato atualizado com sucesso.' }
        else
          format.html do
            redirect_to @contrato, flash: { error: 'Plano da conexão é diferente que o plano do contrato.' }
          end
        end
        format.json { render :show, status: :ok, location: @contrato }
      else
        format.html { render :edit }
        format.json { render json: @contrato.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contratos/1
  # DELETE /contratos/1.json
  def destroy
    respond_to do |format|
      if @contrato.destroy
        format.html { redirect_to contratos_url, notice: 'Contrato excluido com sucesso.' }
        format.json { head :no_content }
      else
        format.html { render :edit }
        format.json { render json: @contrato.errors, status: :unprocessable_entity }
      end
    end
  end

  def autentique
    pdf = WickedPdf.new.pdf_from_string(
      ContratosController.render(
        template: 'contratos/termo.pdf',
        assigns: { contrato: @contrato }
      ),
      encoding: 'UTF-8',
      zoom: 1.2,
      margin: { top: 15, bottom: 18, left: 15, right: 15 },
      page_size: 'A4'
    )

    variables = JSON.parse(ContratosController.render(
                             template: 'contratos/termo.json',
                             assigns: { contrato: @contrato }
                           ), { symbolize_names: true })

    result = Autentique::Client.query(
      Autentique::CriarDocumento,
      variables: variables,
      file: UploadIO.new(StringIO.new(pdf), 'application/pdf', 'termo.pdf')
    )

    respond_to do |format|
      format.html { redirect_to @contrato, notice: 'Termo de adesão enviado com sucesso.' }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_contrato
    @contrato = Contrato.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def contrato_params
    params.require(:contrato).permit(
      :pessoa_id, :plano_id, :pagamento_perfil_id, :status, :dia_vencimento,
      :adesao, :valor_instalacao, :numero_conexoes, :cancelamento, :emite_nf,
      :primeiro_vencimento, :prazo_meses, :parcelas_instalacao, :descricao_personalizada,
      :valor_personalizado
    )
  end

  def assinatura_params
    params.require(:contrato).permit(
      :billing_nome_completo, :billing_cpf, :billing_endereco, :billing_endereco_numero,
      :billing_bairro, :billing_cidade, :billing_estado, :billing_cep, :cartao_parcial
    )
  end

  def verificar_conexoes_planos?
    @contrato.conexoes.all? { |c| c.plano == @contrato.plano }
  end
end

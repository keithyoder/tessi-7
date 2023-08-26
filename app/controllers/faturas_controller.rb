# frozen_string_literal: true

class FaturasController < ApplicationController
  load_and_authorize_resource
  before_action :set_fatura, only: %i[show edit update destroy liquidacao boleto gerar_nf]

  # GET /faturas
  # GET /faturas.json
  def index
    if params.key?(:inadimplentes)
      @faturas = Fatura.inadimplentes.order(vencimento: :desc).page params[:page]
    elsif params.key?(:suspensos)
      @faturas = Fatura.suspensos.order(vencimento: :desc).page params[:page]
    else
      @q = Fatura.ransack(params[:q])
      @faturas = @q.result(vencimento: :desc).page params[:page]
    end
  end

  # GET /faturas/1
  # GET /faturas/1.json
  def show; end

  # GET /faturas/new
  def new
    @fatura = Fatura.new
  end

  # GET /faturas/1/edit
  def edit; end

  def liquidacao
    # @fatura.liquidacao = Date.today
    @fatura.meio_liquidacao = :Dinheiro
    respond_to do |format|
      format.html { render :liquidacao }
      format.json { render json: @fatura.errors, status: :unprocessable_entity }
    end
  end

  def boleto
    send_data @fatura.boleto.to_pdf, filename: 'boleto.pdf', type: :pdf, disposition: 'inline'
  end

  def estornar
    if @fatura.estornar?
      @fatura.update!(liquidacao: nil)
      respond_to do |format|
        format.html { redirect_to @fatura.contrato, notice: 'Fatura estornada com sucesso.' }
      end
    else
      format.html { render :edit }
    end
  end

  def cancelar
    if @fatura.cancelar?
      @fatura.update!(cancelamento: DateTime.now)
      respond_to do |format|
        format.html { redirect_to @fatura.contrato, notice: 'Fatura cancelada com sucesso.' }
      end
    else
      format.html { render :edit }
    end
  end

  def gerar_nf
    respond_to do |format|
      if @fatura.nf21.blank?
        @fatura.gerar_nota
        format.html { redirect_to @fatura, notice: 'Nota Fiscal criada com sucesso.' }
      else
        format.html { redirect_to @fatura, error: 'Nota Fiscal já existe' }
      end
    end
  end

  # POST /faturas
  # POST /faturas.json
  def create
    @fatura = Fatura.new(fatura_params)

    respond_to do |format|
      if @fatura.save
        format.html { redirect_to @fatura, notice: 'Fatura was successfully created.' }
        format.json { render :show, status: :created, location: @fatura }
      else
        format.html { render :new }
        format.json { render json: @fatura.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /faturas/1
  # PATCH/PUT /faturas/1.json
  def update
    respond_to do |format|
      if @fatura.update(fatura_params)
        format.html { redirect_to @fatura, notice: 'Fatura alterada com sucesso.' }
        format.json { render :show, status: :ok, location: @fatura }
      else
        if @fatura.errors.full_messages_for(:liquidacao).present?
          format.html { render :liquidacao }
        else
          format.html { render :edit }
        end
        format.json { render json: @fatura.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /faturas/1
  # DELETE /faturas/1.json
  def destroy
    contrato = @fatura.contrato
    @fatura.destroy
    respond_to do |format|
      format.html { redirect_to contrato, notice: 'Fatura excluída com sucesso.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_fatura
    @fatura = Fatura.find(params[:id])
    @fatura.contrato.conexoes.each { |c| c.current_user = current_user }
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def fatura_params
    params.require(:fatura).permit(
      :valor, :vencimento, :nossonumero, :parcela, :juros_recebidos, :desconto_concedido,
      :data_cancelamento, :meio_liquidacao, :valor_liquidacao, :liquidacao
    )
  end
end

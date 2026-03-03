# frozen_string_literal: true

class FaturasController < ApplicationController
  load_and_authorize_resource
  before_action :set_fatura, only: %i[show edit update destroy liquidacao boleto]

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

  def show; end

  def new
    @fatura = Fatura.new
  end

  def edit; end

  def liquidacao
    @fatura.meio_liquidacao = :Dinheiro
    render :liquidacao
  end

  def boleto
    send_data @fatura.boleto.to_pdf, filename: 'boleto.pdf', type: :pdf, disposition: 'inline'
  end

  def estornar
    if @fatura.estornar?
      @fatura.update!(liquidacao: nil)
      redirect_to @fatura.contrato, notice: t('.notice')
    else
      render :edit
    end
  end

  def cancelar
    if @fatura.cancelar?
      @fatura.update!(cancelamento: DateTime.now)
      redirect_to @fatura.contrato, notice: t('.notice')
    else
      render :edit
    end
  end

  def create
    @fatura = Fatura.new(fatura_params)

    if @fatura.save
      redirect_to @fatura, notice: t('.notice')
    else
      render :new
    end
  end

  def update
    if valor_alterado?
      nova_fatura = Faturas::AtualizarValorService.call(
        fatura: @fatura,
        novo_valor: fatura_params[:valor]
      )
      redirect_to nova_fatura.contrato, notice: t('.valor_atualizado')
    elsif @fatura.update(fatura_params)
      redirect_to @fatura, notice: t('.notice')
    elsif @fatura.errors.full_messages_for(:liquidacao).present?
      render :liquidacao
    else
      render :edit
    end
  rescue ArgumentError => e
    flash.now[:alert] = e.message
    render :edit, status: :unprocessable_content
  end

  def destroy
    contrato = @fatura.contrato
    @fatura.destroy
    redirect_to contrato, notice: t('.notice')
  end

  private

  def set_fatura
    @fatura = Fatura.find(params[:id])
    @fatura.contrato.conexoes.each { |c| c.current_user = current_user }
  end

  def fatura_params
    params.require(:fatura).permit(
      :valor, :vencimento, :nossonumero, :parcela, :juros_recebidos, :desconto_concedido,
      :data_cancelamento, :meio_liquidacao, :valor_liquidacao, :liquidacao
    )
  end

  def valor_alterado?
    fatura_params[:valor].present? && fatura_params[:valor].to_d != @fatura.valor
  end
end

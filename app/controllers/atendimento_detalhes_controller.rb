# frozen_string_literal: true

class AtendimentoDetalhesController < ApplicationController
  before_action :set_atendimento_detalhe, only: %i[show edit update destroy]
  load_and_authorize_resource

  # GET /atendimento_detalhes/1 or /atendimento_detalhes/1.json
  def show; end

  # GET /atendimento_detalhes/new
  def new
    @atendimento = Atendimento.find(params[:atendimento_id])
    @atendimento_detalhe = AtendimentoDetalhe.new(
      atendimento_id: params[:atendimento_id],
      atendente: current_user
    )
  end

  # GET /atendimento_detalhes/1/edit
  def edit; end

  # POST /atendimento_detalhes or /atendimento_detalhes.json
  def create
    @atendimento_detalhe = AtendimentoDetalhe.new(atendimento_detalhe_params)

    respond_to do |format|
      if @atendimento_detalhe.save
        format.html { redirect_to @atendimento_detalhe.atendimento, notice: 'Atendimento detalhe criado com sucesso.' }
        format.json { render :show, status: :created, location: @atendimento_detalhe }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @atendimento_detalhe.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /atendimento_detalhes/1 or /atendimento_detalhes/1.json
  def update
    respond_to do |format|
      if @atendimento_detalhe.update(atendimento_detalhe_params)
        format.html { redirect_to @atendimento_detalhe, notice: 'Atendimento detalhe was successfully updated.' }
        format.json { render :show, status: :ok, location: @atendimento_detalhe }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @atendimento_detalhe.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /atendimento_detalhes/1 or /atendimento_detalhes/1.json
  def destroy
    atendimento = @atendimento_detalhe.atendimento
    @atendimento_detalhe.destroy
    respond_to do |format|
      format.html { redirect_to atendimento, notice: 'Atendimento detalhe was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_atendimento_detalhe
    @atendimento_detalhe = AtendimentoDetalhe.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def atendimento_detalhe_params
    params.require(:atendimento_detalhe).permit(:atendimento_id, :tipo, :atendente_id, :descricao)
  end
end

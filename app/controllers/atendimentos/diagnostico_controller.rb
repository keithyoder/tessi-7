# frozen_string_literal: true

class Atendimentos::DiagnosticoController < ApplicationController
  authorize_resource class: false

  def show
    @motivos = motivos_disponiveis
  end

  def buscar
    cpf       = params[:cpf].to_s.strip
    resultado = Atendimentos::BuscaErpService.call(cpf)

    if resultado.nil?
      @erro = 'CPF não encontrado no sistema.'
    else
      @cliente  = resultado[:cliente]
      @conexoes = resultado[:conexoes]
      @motivos  = motivos_disponiveis
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  def create
    @motivos    = motivos_disponiveis
    @motivo     = params[:motivo]
    @conexao_id = params[:conexao_id].to_i

    contexto = carregar_contexto
    if contexto.nil?
      @erro = 'Contexto não encontrado.'
      respond_to { |f| f.turbo_stream }
      return
    end

    @cliente  = contexto[:cliente]
    @conexao  = contexto[:conexao]

    resultado_diagnostico = Atendimentos::DiagnosticoService.new(
      cliente: @cliente,
      contrato: @conexao,
      motivo: @motivo,
      mensagens: mensagens_parsed
    ).call

    @mensagens       = mensagens_parsed + [{ 'role' => 'assistant', 'content' => resultado_diagnostico }]
    @contexto_serial = contexto[:serializado]

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  # On the first message, fetch from ERP and serialize.
  # On followup messages, deserialize from the hidden field — no ERP hit.
  def carregar_contexto
    if params[:contexto_erp].present?
      dados    = JSON.parse(params[:contexto_erp], symbolize_names: true)
      conexao  = dados[:conexoes].find { |c| c[:id] == @conexao_id }
      return nil if conexao.nil?

      {
        cliente: dados[:cliente],
        conexao: conexao,
        serializado: params[:contexto_erp]
      }
    else
      resultado = Atendimentos::BuscaErpService.call(params[:cpf].to_s.strip)
      return nil if resultado.nil?

      conexao = resultado[:conexoes].find { |c| c[:id] == @conexao_id }
      return nil if conexao.nil?

      {
        cliente: resultado[:cliente],
        conexao: conexao,
        serializado: resultado.to_json
      }
    end
  end

  def mensagens_parsed
    JSON.parse(params[:mensagens] || '[]')
  rescue JSON::ParserError
    []
  end

  def motivos_disponiveis
    {
      'sem_acesso' => 'Sem acesso',
      'lento' => 'Internet lenta',
      'desbloqueio' => 'Desbloqueio',
      'fatura' => 'Fatura / boleto'
    }
  end
end

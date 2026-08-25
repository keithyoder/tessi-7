# frozen_string_literal: true

class Efi::ReconciliarPagamentosService
  def self.executar(periodo, log_a_cada: 25)
    new(periodo, log_a_cada:).executar
  end

  def initialize(periodo, log_a_cada: 25)
    @periodo = periodo
    @log_a_cada = log_a_cada
    @ok = 0
    @pendentes = []
    @erros = []
  end

  def executar
    total = eventos.count
    puts "== Reconciliação Efi (#{@periodo}) — #{total} eventos =="

    processados = 0
    eventos.find_each do |evento|
      processados += 1
      verificar(evento)

      if (processados % @log_a_cada).zero? || processados == total
        puts "[#{processados}/#{total}] ok=#{@ok} pendentes=#{@pendentes.size} erros=#{@erros.size}"
      end
    end

    relatorio
    { ok: @ok, pendentes: @pendentes, erros: @erros }
  end

  private

  def eventos
    WebhookEvento
      .joins(:webhook)
      .where(webhooks: { tipo: :gerencianet }, created_at: @periodo, processed_at: nil)
  end

  def verificar(evento)
    notificacao = Efi::Notification.new(evento.notificacao)

    return unless notificacao.payload['code'] == 200
    return unless notificacao.pago

    valor_pago = notificacao.pago['value'] / 100.0
    fatura = buscar_fatura(notificacao)

    if fatura.nil?
      registrar_pendencia(pendencia_fatura_nao_encontrada(evento, notificacao, valor_pago))
    elsif fatura.liquidacao.blank?
      registrar_pendencia(
        evento_id: evento.id,
        fatura_id: fatura.id,
        motivo: 'pago na Efi mas sem liquidacao registrada',
        valor: valor_pago,
        recebido_em: notificacao.pago['received_by_bank_at'] || notificacao.pago['created_at']
      )
    else
      @ok += 1
    end
  rescue StandardError => e
    erro = { evento_id: evento.id, erro: "#{e.class}: #{e.message}" }
    @erros << erro
    puts "  ! erro evento=#{erro[:evento_id]} #{erro[:erro]}"
  end

  def pendencia_fatura_nao_encontrada(evento, notificacao, valor_pago)
    detalhes = detalhes_cobranca(notificacao)
    {
      evento_id: evento.id,
      motivo: 'fatura não encontrada',
      valor: valor_pago,
      custom_id: notificacao.custom_id,
      charge_id: notificacao.charge_id,
      nome: detalhes[:nome],
      cpf_cnpj: detalhes[:cpf_cnpj]
    }
  end

  def detalhes_cobranca(notificacao)
    return {} if notificacao.charge_id.blank?

    cobranca = GerencianetClient.cliente.detail_charge(params: { id: notificacao.charge_id })
    customer = cobranca.dig('data', 'customer') ||
               cobranca.dig('data', 'payment', 'banking_billet', 'customer') || {}

    nome = customer['name'] || customer.dig('juridical_person', 'corporate_name')
    cpf_cnpj = customer['cpf'] || customer.dig('juridical_person', 'cnpj')

    if nome.blank?
      puts "    (não achei o nome no formato esperado, payload completo da cobrança #{notificacao.charge_id}:)"
      puts "    #{cobranca.inspect}"
    end

    { nome: nome, cpf_cnpj: cpf_cnpj }
  rescue StandardError => e
    puts "    (não foi possível buscar detalhes da cobrança #{notificacao.charge_id}: #{e.message})"
    {}
  end

  def registrar_pendencia(pendencia)
    @pendentes << pendencia
    linha = "  ! pendente evento=#{pendencia[:evento_id]} fatura=#{pendencia[:fatura_id] || '???'} " \
            "valor=#{pendencia[:valor]} motivo=\"#{pendencia[:motivo]}\""
    linha += " nome=\"#{pendencia[:nome]}\" cpf_cnpj=#{pendencia[:cpf_cnpj]}" if pendencia.key?(:nome)
    puts linha
  end

  def buscar_fatura(notificacao)
    notificacao.fatura
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def relatorio
    puts "\n== Resumo =="
    puts "OK (pago e já com liquidacao): #{@ok}"
    puts "Pendentes: #{@pendentes.size}"
    puts "Erros: #{@erros.size}"
  end
end

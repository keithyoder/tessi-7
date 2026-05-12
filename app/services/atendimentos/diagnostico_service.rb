# frozen_string_literal: true

class Atendimentos::DiagnosticoService
  MODEL      = 'claude-haiku-4-5-20251001'
  MAX_TOKENS = 1024
  API_URL    = URI('https://api.anthropic.com/v1/messages').freeze

  MOTIVOS = {
    'sem_acesso' => 'Sem acesso',
    'lento' => 'Internet lenta',
    'desbloqueio' => 'Desbloqueio',
    'fatura' => 'Fatura / boleto'
  }.freeze

  CAUSAS_PROBLEMA = %w[Lost-Carrier Lost-Service NAS-Reboot NAS-Error Admin-Reset].freeze

  class ErroApi < StandardError; end

  def initialize(cliente:, contrato:, motivo:, mensagens: [])
    @cliente   = cliente.with_indifferent_access
    @contrato  = contrato.with_indifferent_access
    @motivo    = motivo
    @mensagens = mensagens
  end

  def call
    call_api
  end

  private

  def escopo_falha
    return 'dispositivo' if @contrato[:roteador_online].to_s == 'true'

    total_rede  = @contrato[:rede_vizinhos_total].to_f
    total_caixa = @contrato[:caixa_vizinhos_total].to_f

    ratio_rede  = total_rede.zero?  ? 1.0 : @contrato[:rede_vizinhos_online].to_f / total_rede
    ratio_caixa = total_caixa.zero? ? 1.0 : @contrato[:caixa_vizinhos_online].to_f / total_caixa

    if ratio_rede < 0.3
      'rede'
    elsif ratio_caixa < 0.5
      'caixa'
    else
      'isolada'
    end
  end

  def resumo_sessoes
    historico = @contrato[:historico_sessoes]
    return 'Sem dados de sessão disponíveis.' if historico.blank?

    linhas = []
    linhas << "Sessão atual iniciada em: #{historico[:sessao_atual_inicio] || 'offline'}"
    linhas << "Sessões nos últimos 7 dias: #{historico[:sessoes_7_dias]}"
    linhas << "Quedas inesperadas (7 dias): #{historico[:quedas_7_dias]}"
    linhas << "Padrão instável: #{historico[:padrao_instavel] ? 'SIM' : 'não'}"
    if historico[:ultima_queda]
      linhas << "Última queda: #{historico[:ultima_queda] || 'nenhuma'} (#{historico[:ultima_causa]})"
    end

    if historico[:sessoes_por_dia].present?
      linhas << "Sessões por dia: #{historico[:sessoes_por_dia].map { |d, n| "#{d}:#{n}" }.join(', ')}"
    end

    t = historico[:transferencia_7_dias]
    if t.present?
      linhas << "Transferência 7 dias: #{t[:download_mb]} MB download / #{t[:upload_mb]} MB upload"
      if t[:por_dia].present?
        linhas << "Transferência por dia: #{t[:por_dia].map do |d, v|
          "#{d}: ↓#{v[:download_mb]}MB ↑#{v[:upload_mb]}MB"
        end.join(', ')}"
      end
    end

    linhas.join("\n")
  end

  def resumo_ping
    ping = @contrato[:ping]
    return 'Ping não disponível.' if ping.blank?

    return "Ping: inacessível — #{ping[:erro]}" unless ping[:acessivel]

    "Ping: #{ping[:latencia_avg_ms]}ms avg / #{ping[:jitter_ms]}ms jitter / #{ping[:perda_percentual]}% perda (#{ping[:pacotes_recebidos]}/#{ping[:pacotes_enviados]} pacotes)"
  end

  def resumo_faturas
    faturas = @contrato[:faturas_abertas]
    proxima = @contrato[:proxima_fatura]
    linhas  = []

    if faturas.present?
      linhas << 'Faturas vencidas:'
      faturas.each do |f|
        linha = "  - #{f[:vencimento]} #{f[:valor]}"
        linha += " | boleto: #{f[:link]}" if f[:link].present?
        linha += " | PIX: #{f[:pix]}" if f[:pix].present?
        linhas << linha
      end
    else
      linhas << 'Sem faturas vencidas.'
    end

    if proxima.present?
      linha = "Próxima fatura: #{proxima[:vencimento]} #{proxima[:valor]}"
      linha += " | boleto: #{proxima[:link]}" if proxima[:link].present?
      linha += " | PIX: #{proxima[:pix]}"     if proxima[:pix].present?
      linhas << linha
    end

    linhas.join("\n")
  end

  def build_system_prompt
    escopo       = escopo_falha
    motivo_label = MOTIVOS[@motivo] || @motivo

    <<~PROMPT
      Você é um assistente interno de suporte técnico da Tessi Telecom.
      Você está ajudando um ATENDENTE — não o cliente final.
      Responda de forma direta e objetiva. Use linguagem técnica quando apropriado.
      Responda sempre em português brasileiro.
      Evite emojis e excesso de formatação markdown. Use texto simples com no máximo um nível de hierarquia.

      DADOS DO CLIENTE (vindos do ERP — não questione):
      - Nome: #{@cliente[:nome]} (#{@cliente[:tipo]})
      - Contrato: #{@contrato[:id]} | Conexão: #{@contrato[:contrato_id]}
      - Endereço: #{@contrato[:endereco]}
      - Plano: #{@contrato[:plano]}
      - Tecnologia: #{@contrato[:tecnologia]&.upcase || 'DESCONHECIDA'}
      - Status: #{@contrato[:status]}
      - Inadimplente: #{@contrato[:inadimplente].to_s == 'true' ? 'SIM' : 'não'}
      - Trust release já usado: #{@contrato[:trust_release_usado].to_s == 'true' ? 'SIM' : 'não'}
      - Roteador online no sistema: #{@contrato[:roteador_online].to_s == 'true' ? 'SIM' : 'não'}
      - #{@contrato[:vizinhos_label]} #{@contrato[:referencia_id]}: #{@contrato[:vizinhos_proximos_online]}/#{@contrato[:vizinhos_proximos_total]} vizinhos online
      #{"- Rede: #{@contrato[:vizinhos_amplos_online]}/#{@contrato[:vizinhos_amplos_total]} vizinhos online" unless @contrato[:vizinhos_label] == @contrato[:vizinhos_amplos_label]}
      - Escopo da falha deduzido: #{escopo}

      FATURAS:
      #{resumo_faturas}

      HISTÓRICO DE SESSÕES:
      #{resumo_sessoes}

      PING:
      #{resumo_ping}

      MOTIVO DO CONTATO: #{motivo_label}

      REGRAS DE NEGÓCIO:
      - NUNCA sugira diagnóstico técnico se o cliente estiver bloqueado por inadimplência — resolva o financeiro primeiro.
      - Desbloqueio via PIX: libera automaticamente ao detectar o pagamento.
      - Desbloqueio via boleto: atendente libera manualmente ao receber o comprovante.
      - Desbloqueio por promessa de pagamento: só permitido se trust_release_usado = false. Se já usado, exigir comprovante antes de liberar.

      TERMINOLOGIA POR TECNOLOGIA:
      - Se tecnologia = RADIO: use "antena", "sinal de rádio", "ponto de acesso (AP)", "interferência", "linha de visada", "CPE". NUNCA mencione ONU, cabo drop, splitter, ou fibra óptica.
      - Se tecnologia = FIBRA: use "ONU", "cabo drop", "splitter", "caixa de atendimento", "sinal óptico". NUNCA mencione antena ou sinal de rádio.

      INTERPRETAÇÃO DO ESCOPO DA FALHA PARA FIBRA:
      - "rede": menos de 30% dos vizinhos online — problema de infraestrutura upstream. Acionar equipe de campo imediatamente.
      - "caixa": menos de 50% dos vizinhos da caixa online — problema no splitter ou cabo feeder. Acionar equipe de campo.
      - "isolada": só este cliente offline, vizinhos ok — tentar reboot primeiro. Se não resolver, acionar equipe para verificar cabo drop ou ONU.
      - "dispositivo": roteador online mas cliente sem acesso — problema local. Guiar troubleshooting no dispositivo do cliente.

      INTERPRETAÇÃO DO ESCOPO DA FALHA PARA RADIO:
      - "rede": menos de 30% dos clientes do ponto online — provável problema no AP ou backhaul. Acionar equipe imediatamente.
      - "isolada": só este cliente offline, outros do ponto ok — verificar alinhamento da antena, obstrução física, ou CPE com defeito.
      - "dispositivo": roteador online mas cliente sem acesso — problema no roteador do cliente ou configuração local.
      - Se todos os vizinhos do ponto aparecem offline: pode ser falha de autenticação RADIUS no ponto, não necessariamente queda de sinal. Verificar se o ponto está autenticando antes de acionar equipe de campo.

      INTERPRETAÇÃO DO PING:
      - Inacessível com roteador online: roteador pode estar bloqueando ICMP — não necessariamente um problema.
      - Latência média > 50ms: pode indicar problema de roteamento ou congestionamento.
      - Jitter > 10ms: conexão instável mesmo que "online".
      - Perda de pacotes > 0%: problema intermitente, mesmo que pequeno.

      INTERPRETAÇÃO DO HISTÓRICO DE SESSÕES:
      - Conexão saudável: ~7 sessões em 7 dias, todas Session-Timeout ou User-Request.
      - Múltiplas sessões por dia com Lost-Carrier (fibra): quedas frequentes, investigar ONU ou cabo drop.
      - Múltiplas sessões por dia com Lost-Carrier (radio): quedas frequentes, investigar alinhamento da antena ou interferência.
      - Zero transferência nas últimas 24h com sessão ativa: conexão "zumbi" — autenticada mas sem tráfego real.
      - Padrão de quedas concentrado num horário: pode ser congestionamento de rede ou interferência de rádio.
    PROMPT
  end

  def call_api
    system_prompt = build_system_prompt

    api_mensagens = if @mensagens.empty?
                      [{ role: 'user', content: 'Analise a situação e me dê o diagnóstico e próximos passos.' }]
                    else
                      @mensagens.map { |m| { role: m['role'], content: m['content'] } }
                    end

    request                    = Net::HTTP::Post.new(API_URL)
    request['Content-Type']    = 'application/json'
    request['x-api-key']       = Rails.application.credentials[:anthropic_api_key]
    request['anthropic-version'] = '2023-06-01'
    request.body = {
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: system_prompt,
      messages: api_mensagens
    }.to_json

    http          = Net::HTTP.new(API_URL.host, API_URL.port)
    http.use_ssl  = true

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise ErroApi, "Anthropic API retornou HTTP #{response.code}: #{response.body.truncate(300)}"
    end

    parsed = JSON.parse(response.body, symbolize_names: true)
    parsed.dig(:content, 0, :text).presence || raise(ErroApi, 'Resposta vazia da API')
  rescue JSON::ParserError => e
    raise ErroApi, "Falha ao parsear resposta da API: #{e.message}"
  end
end

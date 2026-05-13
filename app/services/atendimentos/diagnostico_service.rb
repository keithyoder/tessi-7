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
    h = @contrato[:historico_sessoes]
    return 'Sem dados de sessão disponíveis.' if h.blank?

    linhas = []
    linhas << "Sessão atual iniciada em: #{h[:sessao_atual_inicio] || 'offline'}"
    linhas << "Sessões nos últimos 7 dias: #{h[:sessoes_7_dias]}"
    linhas << "Quedas no lado do cliente (Lost-Carrier/Lost-Service): #{h[:quedas_cliente]}"
    linhas << "Quedas por reinício do NAS: #{h[:quedas_nas]}" if h[:quedas_nas] > 0
    linhas << "Padrão instável: #{h[:padrao_instavel] ? 'SIM' : 'não'}"
    linhas << "Última queda (cliente): #{h[:ultima_queda]} (#{h[:ultima_causa]})" if h[:ultima_queda]

    if h[:sessoes_por_dia].present?
      linhas << "Sessões por dia: #{h[:sessoes_por_dia].map { |d, n| "#{d}:#{n}" }.join(', ')}"
    end

    t = h[:transferencia_7_dias]
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

  def resumo_vizinhos
    qv = @contrato[:quedas_vizinhos]
    return '' if qv.nil?

    linhas = []
    linhas << "Análise de vizinhos na mesma #{@contrato[:vizinhos_label]}:"
    linhas << "  - #{qv[:vizinhos_com_quedas]} de #{qv[:total_vizinhos]} vizinhos também tiveram quedas nos últimos 7 dias"
    linhas << "  - #{qv[:quedas_coincidentes]} de #{qv[:total_quedas_cliente]} quedas do cliente coincidiram com quedas de vizinhos (±1 hora)"
    linhas << "  - Proporção de coincidência: #{(qv[:proporcao_coincidente] * 100).round}%"
    linhas << "  - INFRAESTRUTURA PROVÁVEL: #{qv[:infraestrutura_provavel] ? 'SIM — acionar equipe de campo' : 'não — problema isolado no cliente'}"
    linhas.join("\n")
  end

  def resumo_rede
    qr = @contrato[:quedas_rede]
    return '' if qr.nil?

    linhas = []
    linhas << 'Análise de outras caixas na mesma rede:'
    linhas << "  - #{qr[:conexoes_com_quedas]} de #{qr[:total_conexoes_rede]} conexões em outras caixas tiveram quedas coincidentes"
    linhas << "  - #{qr[:quedas_coincidentes]} de #{qr[:total_quedas_cliente]} quedas do cliente coincidem com outras caixas (±1 hora)"
    linhas << "  - Proporção: #{(qr[:proporcao_coincidente] * 100).round}%"

    if qr[:caixas_afetadas].present?
      afetadas     = qr[:caixas_afetadas].map { |c| c[:nome] }
      nao_afetadas = qr[:caixas_sem_quedas] || []

      linhas << '  Caixas COM quedas coincidentes:'
      qr[:caixas_afetadas].each do |c|
        percentual = (c[:proporcao_coincidente] * 100).round
        linhas << "    - #{c[:nome]}: #{c[:quedas_coincidentes]}/#{qr[:total_quedas_cliente]} quedas do cliente / #{percentual}% das quedas da caixa coincidem"
      end
      linhas << "  Caixas SEM quedas coincidentes: #{nao_afetadas.join(', ')}" if nao_afetadas.any?

      if nao_afetadas.any? && afetadas.any?
        linhas << '  CONCLUSÃO: problema num segmento intermediário — NÃO é a OLT.'
      elsif nao_afetadas.empty?
        linhas << '  CONCLUSÃO: todas as caixas afetadas — verificar OLT ou fibra principal.'
      end
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

      ANÁLISE DE VIZINHOS:
      #{resumo_vizinhos}

      ANÁLISE DA REDE:
      #{resumo_rede}

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
      - ICMP bloqueado + TCP 8087 acessível: roteador DEFINITIVAMENTE online — ignorar resultado do ICMP.
      - ICMP ok + TCP 8087 acessível: roteador online, acesso remoto configurado.
      - ICMP ok + TCP 8087 porta fechada: roteador online, acesso remoto não configurado nesta porta.
      - ICMP bloqueado + TCP 8087 timeout: roteador provavelmente offline — não é possível confirmar.
      - Ambos inacessíveis: roteador offline.
      - Latência ICMP média > 50ms: possível problema de roteamento ou congestionamento.
      - Jitter > 10ms: conexão instável mesmo que online.
      - Perda de pacotes > 0%: problema intermitente, mesmo que pequeno.
      - Latência TCP muito maior que ICMP: possível firewall ou QoS afetando tráfego de gerência.

      INTERPRETAÇÃO DO HISTÓRICO DE SESSÕES:
      - Conexão saudável: ~7 sessões em 7 dias, todas Session-Timeout ou User-Request.
      - Múltiplas sessões por dia com Lost-Carrier (fibra): quedas frequentes, investigar ONU ou cabo drop.
      - Múltiplas sessões por dia com Lost-Carrier (radio): quedas frequentes, investigar alinhamento da antena ou interferência.
      - Zero transferência nas últimas 24h com sessão ativa: conexão "zumbi" — autenticada mas sem tráfego real.
      - Padrão de quedas concentrado num horário: pode ser congestionamento de rede ou interferência de rádio.

      INTERPRETAÇÃO DA ANÁLISE DE REDE:
      - Se TODAS as caixas da rede têm quedas coincidentes: problema na OLT ou fibra principal upstream.
      - Se ALGUMAS caixas têm quedas coincidentes e outras não: problema num segmento intermediário que alimenta apenas as caixas afetadas — NÃO é a OLT. Verificar a fibra entre a OLT e o splitter que serve as caixas afetadas.
      - Se APENAS a caixa do cliente tem quedas: problema no cabo feeder ou splitter daquela caixa específica.
      - Sempre mencionar quais caixas estão afetadas e quais não estão — isso ajuda a localizar o segmento com problema.
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

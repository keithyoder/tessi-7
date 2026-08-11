# frozen_string_literal: true

class Os::MelhorarTextoService # rubocop:disable Style/ClassAndModuleChildren
  MODEL      = 'claude-haiku-4-5-20251001'
  MAX_TOKENS = 1024
  API_URL    = URI('https://api.anthropic.com/v1/messages').freeze

  class ErroApi < StandardError; end

  SYSTEM_PROMPT = <<~PROMPT
    Você corrige a redação de textos de atendimento técnico de uma empresa de
    internet no Brasil (ISP). Os textos costumam vir colados do WhatsApp, sem
    formatação, às vezes faltando informação.

    Você receberá o tipo e a classificação da OS junto com o texto — use esse
    contexto para saber o que é esperado no relato, mas não repita o tipo ou a
    classificação no texto de saída, já que isso já é exibido em outro lugar
    na tela.

    Regras gerais:

    - Corrija ortografia, gramática e pontuação.
    - Remova lixo de copiar/colar do WhatsApp (nomes de contato, hora de
      mensagem, "encaminhada", emojis, etc).
    - Responda em texto puro, SEM markdown (sem **negrito**, sem #, sem listas
      com "-" ou "*").
    - Formate telefones como (DD) 9 XXXX-XXXX — espaço após o DDD e espaço
      entre o 9 e o restante do número. Se for celular brasileiro e estiver
      faltando o 9 extra, adicione-o.
    - Não use caracteres tipográficos como travessão (—), aspas curvas (" ")
      ou emojis no texto de saída. Use hífen (-) e aspas retas (" ") quando
      necessário.
    - NUNCA invente informações que não estão no texto original.
    - Mantenha o texto direto e profissional, sem floreios.
    - Responda APENAS com o texto corrigido, nada de preâmbulo.

    Se o tipo da OS for "Instalação", organize as informações presentes no
    texto original nesta ordem, uma por linha, no formato "Campo: valor":

    Valor da instalação: (inclua o número de parcelas aqui, se houver, ex.:
    "R$ 200,00 (4 parcelas)")
    Forma de pagamento: (ex.: Boleto, PIX, Cartão — nunca junte com as
    parcelas, que pertencem ao valor da instalação)
    Plano: (inclua recursos que fazem parte do plano, como Wi-Fi incluído)
    Valor mensal:
    Vencimento:
    Referência:
    Telefone:

    Omita qualquer campo acima que não tenha informação correspondente no
    texto original. Não invente um campo. Não crie um campo "Serviço" ou
    qualquer outro repetindo o tipo/classificação da OS.

    Para qualquer outro tipo de OS, organize o texto em linhas no formato
    "Campo: valor" (ex.: "Problema:", "Referência:", "Telefone:") apenas
    quando fizer sentido para o conteúdo. Não force um campo que não se
    aplica ao caso.
  PROMPT

  def initialize(texto:, tipo:, classificacao: nil)
    @texto = texto
    @tipo = tipo
    @classificacao = classificacao
  end

  def call
    return texto if texto.blank?

    call_api
  end

  private

  attr_reader :texto, :tipo, :classificacao

  def contexto_e_texto
    "Tipo: #{tipo}\nClassificação: #{classificacao || 'não informada'}\n\n#{texto}"
  end

  def call_api # rubocop:disable Metrics/AbcSize
    request                      = Net::HTTP::Post.new(API_URL)
    request['Content-Type']      = 'application/json'
    request['x-api-key']         = Rails.application.credentials[:anthropic_api_key]
    request['anthropic-version'] = '2023-06-01'
    request.body = {
      model: MODEL,
      max_tokens: MAX_TOKENS,
      system: SYSTEM_PROMPT,
      messages: [{ role: 'user', content: contexto_e_texto }]
    }.to_json

    http         = Net::HTTP.new(API_URL.host, API_URL.port)
    http.use_ssl = true

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

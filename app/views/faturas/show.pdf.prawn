prawn_document(page_size: 'A5', margin: [12,12,12,12]) do |pdf|
  pdf.font_families.update('OpenSans' => {
    normal: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
    italic: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
    bold: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
    bold_italic: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf'
  })
  pdf.font 'OpenSans'
  esquerda = 13

  canhoto = {
    'Assinante': @fatura.pessoa.nome,
    'Contrato': @fatura.contrato.id,
    'Nosso Número': @fatura.nossonumero,
    'Parcela': @fatura.parcela,
    'Valor': number_to_currency(@fatura.valor_liquidacao),
    'Vencimento': l(@fatura.vencimento),
    'Liquidação': l(@fatura.liquidacao),
    'Recebido por': current_user.primeiro_nome,
  }

  pdf.draw_text 'Liquidação Manual', size: 16, style: :bold, at: [esquerda, 480]

  vertical = 460
  canhoto.each do |key, value|
    pdf.draw_text key, size: 12, style: :bold, at: [esquerda, vertical]
    pdf.draw_text value, size: 12, style: :bold, at: [esquerda + 100, vertical]
    vertical -= 20
  end

  pdf.svg IO.read(Rails.root / 'app' / 'assets' / 'images' / 'logo-cores.svg'), at: [10, 265], width: 100
  pdf.rounded_rectangle [0, 270], 390, 270, 10
  pdf.draw_text 'RECIBO', size: 24, style: :bold, at: [150, 235]
  pdf.rounded_rectangle [260, 260], 120, 40, 5
  pdf.text_box number_to_currency(@fatura.valor_liquidacao), size: 24, style: :bold, at: [265,250], width: 100, align: :center
  pdf.rounded_rectangle [10, 210], 370, 50, 5
  pdf.rounded_rectangle [10, 155], 370, 50, 5
  pdf.rounded_rectangle [10, 100], 370, 60, 5
  pdf.rounded_rectangle [10, 35], 180, 25, 5
  pdf.rounded_rectangle [200, 35], 180, 25, 5
  pdf.close_and_stroke
  pdf.draw_text 'Prestadora', size: 8, style: :bold, at: [esquerda, 202]
  pdf.draw_text Setting.razao_social, size: 10, at: [esquerda, 190]
  pdf.draw_text "CNPJ: #{CNPJ.new(Setting.cnpj).formatted}", size: 10, at: [esquerda, 178]
  pdf.draw_text 'Rua Treze de Maio, 5B - Centro - Pesqueira - PE', size: 10, at: [esquerda, 166]
  pdf.draw_text 'Assinante', size: 8, style: :bold, at: [esquerda, 147]
  pdf.draw_text @fatura.pessoa.nome, size: 10, at: [esquerda, 136]
  pdf.draw_text 'CPF: ' + @fatura.pessoa.cpf.to_s, size: 10, at: [esquerda, 124]
  pdf.draw_text (@fatura.pessoa.endereco + ' - ' + @fatura.pessoa.bairro.nome_cidade_uf), size: 10, at: [esquerda,112]
  extenso = <<-STRING
    Recebemos de #{@fatura.pessoa.nome} a importância de #{number_to_currency(@fatura.valor_liquidacao)} (#{Extenso.moeda(@fatura.valor_liquidacao).downcase}) como quitação da parcela #{@fatura.parcela} do contrato #{@fatura.contrato.id}, vencida no dia #{l(@fatura.vencimento)} referente ao serviço de conexão à internet no plano #{@fatura.contrato.plano.nome} durante o período de #{l(@fatura.periodo_inicio)} a #{l(@fatura.periodo_fim)}.
  STRING

  pdf.text_box extenso, size: 10, at: [esquerda, 96], width: 365
  pdf.text_box 'Pesqueira, '+l(@fatura.liquidacao, :default => ''), size: 12, style: :bold, at: [200,28], :width => 180, :align => :center
  pdf.text_box current_user.primeiro_nome, size: 12, style: :bold, at: [esquerda,28], :width => 180, :align => :center
end

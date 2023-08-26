# frozen_string_literal: true

require 'prawn/measurement_extensions'
prawn_document(page_size: 'A4', margin: [20.mm, 20.mm, 20.mm, 20.mm]) do |pdf|
  # pdf.font_families.update("Arial Unicode MS"=>{:normal =>(Rails.root / 'app' / 'assets' / 'images' / 'arial.ttf')})
  # pdf.font "Arial Unicode MS"
  # pdf.font "/Library/Fonts/Arial Unicode.ttf"
  pdf.font_families.update('OpenSans' => {
                             normal: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
                             italic: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
                             bold: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-ExtraBold.ttf',
                             bold_italic: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf'
                           })
  pdf.font 'OpenSans'

  # página inteira
  pdf.rectangle [0.mm, 260.mm], 168.mm, 260.mm
  # nota fiscal de servico de comunicacao
  pdf.rectangle [0.mm, 232.mm], 168.mm, 8.mm

  # número
  pdf.rectangle [0.mm, 224.mm], 42.mm, 10.mm
  # série
  pdf.rectangle [42.mm, 224.mm], 42.mm, 10.mm
  # cfop
  pdf.rectangle [84.mm, 224.mm], 42.mm, 10.mm
  # emissão
  pdf.rectangle [126.mm, 224.mm], 42.mm, 10.mm

  # referencia
  pdf.rectangle [0.mm, 214.mm], 35.mm, 10.mm
  # base calculo
  pdf.rectangle [35.mm, 214.mm], 35.mm, 10.mm
  # valor icms
  pdf.rectangle [70.mm, 214.mm], 35.mm, 10.mm
  # situação
  pdf.rectangle [105.mm, 214.mm], 63.mm, 10.mm

  # valor total
  pdf.rectangle [126.mm, 15.mm], 42.mm, 10.mm
  # chave digital
  pdf.rectangle [0.mm, 15.mm], 126.mm, 10.mm
  # header de itens
  pdf.rectangle [0.mm, 165.mm], 168.mm, 5.mm
  # descricao
  pdf.rectangle [0.mm, 165.mm], 84.mm, 90.mm
  # valor total
  pdf.rectangle [84.mm, 165.mm], 28.mm, 90.mm
  # base de calculo
  pdf.rectangle [112.mm, 165.mm], 28.mm, 90.mm
  # aliquota
  pdf.rectangle [140.mm, 165.mm], 28.mm, 90.mm
  pdf.close_and_stroke

  pdf.draw_text 'NÚMERO', size: 8, at: [1.mm, 221.mm]
  pdf.draw_text 'SÉRIE', size: 8, at: [43.mm, 221.mm]
  pdf.draw_text 'CFOP', size: 8, at: [85.mm, 221.mm]
  pdf.draw_text 'EMISSÃO', size: 8, at: [127.mm, 221.mm]
  pdf.draw_text 'REFERÊNCIA', size: 8, at: [1.mm, 211.mm]
  pdf.draw_text 'BASE DE CÁCLULO', size: 8, at: [36.mm, 211.mm]
  pdf.draw_text 'VALOR DO ICMS', size: 8, at: [71.mm, 211.mm]
  pdf.draw_text 'SITUAÇÃO DO DOCUMENTO FISCAL', size: 8, at: [106.mm, 211.mm]

  pdf.draw_text 'VALOR TOTAL DA NOTA', size: 8, at: [127.mm, 12.mm]
  pdf.draw_text 'AUTENTICAÇÃO DIGITAL', size: 8, at: [1.mm, 12.mm]
  pdf.draw_text 'Contribuição para o FUST e FUNTTEL - 1,5% do valor dos serviços - Não repassada às tarifas.', size: 8,
                                                                                                               at: [25.mm, 1.mm]

  esquerda = 60.mm
  pdf.svg IO.read(Rails.root / 'app' / 'assets' / 'images' / 'logo-cores.svg'), at: [0.mm, 260.mm], width: 50.mm
  pdf.draw_text Setting.razao_social, size: 12, at: [esquerda, 255.mm]
  pdf.draw_text 'Rua Treze de Maio, 5B', size: 10, at: [esquerda, 249.mm]
  pdf.draw_text 'Centro - Pesqueira - PE - 55.200-000', size: 10, at: [esquerda, 244.mm]
  pdf.draw_text "CNPJ: #{CNPJ.new(@nf21.parsed_mestre(:cnpj_emitente)).formatted} / IE: #{Setting.ie}", size: 10,
                                                                                                        at: [esquerda, 239.mm]
  pdf.draw_text "Telefone: #{Setting.telefone} / Site: #{Setting.site}", size: 10, at: [esquerda, 234.mm]

  pdf.text_box 'NOTA FISCAL DE SERVIÇO DE COMUNICAÇÃO - MODELO 21', size: 14, style: :bold, at: [2.mm, 230.mm],
                                                                    width: 168.mm, height: 8.mm, align: :center
  pdf.text_box @nf21.parsed_mestre(:numero), size: 12, at: [1.mm, 219.mm], width: 40.mm, height: 8.mm, align: :right
  pdf.text_box 'Única', size: 12, at: [42.mm, 219.mm], width: 40.mm, height: 8.mm, align: :right
  pdf.text_box @nf21.nf21_itens.first.parsed_item(:cfop), size: 12, at: [84.mm, 219.mm], width: 40.mm, height: 8.mm,
                                                          align: :right
  pdf.text_box l(@nf21.emissao), size: 12, at: [126.mm, 219.mm], width: 40.mm, height: 8.mm, align: :right

  referencia = @nf21.parsed_mestre(:referencia)
  pdf.text_box "#{referencia[2..3]}/20#{referencia[0..1]}", size: 12, at: [1.mm, 209.mm], width: 33.mm, height: 8.mm,
                                                            align: :right
  pdf.text_box number_to_currency(@nf21.parsed_mestre(:bc_icms).to_i / 100.0), size: 12, at: [35.mm, 209.mm],
                                                                               width: 33.mm, height: 8.mm, align: :right
  pdf.text_box number_to_currency(@nf21.parsed_mestre(:icms).to_i / 100.0), size: 12, at: [70.mm, 209.mm],
                                                                            width: 33.mm, height: 8.mm, align: :right
  pdf.text_box 'Normal', size: 12, at: [106.mm, 209.mm], width: 60.mm, height: 8.mm, align: :right

  esquerda = 2.mm
  endereco1 = "#{@nf21.parsed_cadastro(:logradouro)}, #{@nf21.parsed_cadastro(:numero)} - #{@nf21.parsed_cadastro(:complemento)}"
  endereco2 = "#{@nf21.parsed_cadastro(:bairro)} - #{@nf21.parsed_cadastro(:municipio).upcase} - #{@nf21.parsed_cadastro(:uf)} - #{@nf21.parsed_cadastro(:cep)}"
  cpf_cnpj = if @nf21.parsed_mestre(:tipo_campo_1).to_i == 1
               CNPJ.new(@nf21.parsed_mestre(:cnpj_cpf))
             else
               CPF.new(@nf21.parsed_mestre(:cnpj_cpf).last(11))
             end
  pdf.draw_text 'ASSINANTE', size: 8, style: :bold, at: [esquerda, 195.mm]
  pdf.draw_text @nf21.parsed_cadastro(:razao_social), size: 12, at: [esquerda, 190.mm]
  pdf.draw_text endereco1, size: 10, at: [esquerda, 185.mm]
  pdf.draw_text endereco2, size: 10, at: [esquerda, 180.mm]
  pdf.draw_text "#{@nf21.fatura.pessoa.tipo_documento}: #{cpf_cnpj.formatted}", size: 10, at: [esquerda, 175.mm]
  pdf.draw_text "IE: #{@nf21.fatura.pessoa.ie.presence || 'ISENTO'}", size: 10, at: [esquerda + 55.mm, 175.mm]

  pdf.text_box 'DESCRIÇÃO DOS SERVIÇOS', size: 8, style: :bold, at: [esquerda, 163.mm], width:  85.mm, align: :center
  pdf.text_box 'VALOR TOTAL', size: 8, style: :bold, at: [85.mm, 163.mm], width: 26.mm, align: :center
  pdf.text_box 'BASE DE CÁLCULO', size: 8, style: :bold, at: [113.mm, 163.mm], width: 26.mm, align: :center
  pdf.text_box 'ALÍQUOTA ICMS', size: 8, style: :bold, at: [141.mm, 163.mm], width: 26.mm, align: :center
  pdf.text_box "Serviço de comunicação multimídia\n Plano #{@nf21.nf21_itens.first.parsed_item(:descricao)}", size: 12,
                                                                                                              at: [esquerda, 158.mm], leading: 7, width: 120.mm, height: 100.mm
  pdf.text_box "Período de Utilização: #{l(@nf21.fatura.periodo_inicio)} - #{l(@nf21.fatura.periodo_fim)}", size: 10,
                                                                                                            at: [esquerda, 144.mm], width: 85.mm, height: 8.mm
  pdf.text_box "Fatura de Referência: #{@nf21.fatura.id.to_s.rjust(8, '0')}", size: 10, at: [esquerda, 138.mm],
                                                                              width: 82.mm, height: 8.mm
  if @nf21.fatura.contrato.endereco_instalacao_diferente?
    pdf.text_box 'Endereço de Instalação:', size: 10, at: [esquerda, 132.mm], width: 82.mm, height: 8.mm
    y = 126
    @nf21.fatura.contrato.enderecos.each do |endereco|
      pdf.text_box endereco, size: 10, at: [esquerda, y.mm], width: 82.mm, height: 9.mm
      y -= 6
    end
  end
  pdf.text_box number_to_currency(@nf21.nf21_itens.first.parsed_item(:valor_total).to_i / 100.0), size: 12,
                                                                                                  at: [85.mm, 158.mm], width: 26.mm, align: :right
  pdf.text_box number_to_currency(@nf21.nf21_itens.first.parsed_item(:bc_icms).to_i / 100.0), size: 12,
                                                                                              at: [113.mm, 158.mm], width: 26.mm, align: :right
  pdf.text_box "#{@nf21.nf21_itens.first.parsed_item(:aliquota).to_i}%", size: 12, at: [141.mm, 158.mm],
                                                                         width: 26.mm, align: :right

  pdf.draw_text 'OBSERVAÇÕES', size: 8, style: :bold, at: [esquerda, 70.mm]
  pdf.text_box "NATUREZA DA OPERAÇÃO: Prestação de Serviço de Comunicação
    Documento emitido por ME ou EPP optante do Simples Nacional.
    Não gera direito a crédito fiscal de IPI,

    Valor aproximado dos Tributos Federais: 13,45% e Municipais: 2,00%
    Fonte IBPT Chave BEA5CD", size: 10, at: [esquerda, 65.mm], leading: 7, width:  120.mm, height: 50.mm

  pdf.text_box number_to_currency(@nf21.parsed_mestre(:valor_total).to_i / 100.0), size: 14, style: :bold,
                                                                                   at: [126.mm, 10.mm], width: 40.mm, height: 8.mm, align: :right
  pdf.text_box @nf21.parsed_mestre(:codigo_autenticacao).upcase.gsub(/(.{4})(?=.)/, '\1.\2'), size: 12,
                                                                                              at: [1.mm, 10.mm], width: 126.mm, height: 8.mm, align: :center
end

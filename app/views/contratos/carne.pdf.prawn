require 'prawn/measurement_extensions'

margem = 5.send(:mm)

prawn_document(page_size: 'A4', margin: [margem, margem, margem, margem]) do |pdf|
  pdf.font_families.update('OpenSans' => {
    normal: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
    italic: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf',
    bold: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-ExtraBold.ttf',
    bold_italic: Rails.root / 'app' / 'assets' / 'fonts' / 'OpenSans-Regular.ttf'
  })
  pdf.font 'OpenSans'
  superior = 297.send(:mm) - margem * 2
  canhoto = 50.send(:mm)
  boleto = 150.send(:mm)
  instrucoes = 124.send(:mm)
  linha = 6.send(:mm)

  contar = 0
  @faturas.each do |fatura|
    if (contar > 0 && contar % 3 == 0)
      pdf.start_new_page
    end
    y = superior - (contar % 3 * 99.send(:mm) + 1)
    pdf.font_size 5

    # boleto
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha * 2
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha * 3
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha * 4
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha * 5
    pdf.stroke_horizontal_line canhoto + instrucoes, canhoto + boleto, at: y - linha * 6
    pdf.stroke_horizontal_line canhoto + instrucoes, canhoto + boleto, at: y - linha * 7 
    pdf.stroke_horizontal_line canhoto + instrucoes, canhoto + boleto, at: y - linha * 8 
    pdf.stroke_horizontal_line canhoto + instrucoes, canhoto + boleto, at: y - linha * 9 
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha * 10
    pdf.stroke_horizontal_line canhoto, canhoto + boleto, at: y - linha * 12.5
    #pdf.stroke_horizontal_line canhoto + 97.send(:mm), canhoto + boleto, at: y - linha * 8
    pdf.stroke_vertical_line(y - linha * 3, y - linha * 5, at: canhoto + 24.send(:mm)) 
    pdf.stroke_vertical_line(y - linha * 3, y - linha * 5, at: canhoto + 49.send(:mm)) 
    pdf.stroke_vertical_line(y - linha * 3, y - linha * 5, at: canhoto + 73.send(:mm)) 
    pdf.stroke_vertical_line(y - linha * 3, y - linha * 5, at: canhoto + 97.send(:mm)) 
    pdf.stroke_vertical_line(y - linha * 1, y - linha * 10, at: canhoto + instrucoes) 
    pdf.stroke_vertical_line(y - 2.send(:mm), y - linha, at: canhoto + 30.send(:mm)) 
    pdf.stroke_vertical_line(y - 2.send(:mm), y - linha, at: canhoto + 43.send(:mm))

    pdf.draw_text 'Local de Pagamento', at: [canhoto, y + 1.send(:mm) - linha * 1.5]
    pdf.draw_text 'Beneficário', at: [canhoto, y + 1.send(:mm) - linha * 2.5]
    pdf.draw_text 'Data do Documento', at: [canhoto, y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text 'Uso do Banco', at: [canhoto, y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text 'Instruções', at: [canhoto, y + 1.send(:mm) - linha * 5.5]
    pdf.draw_text 'Sacado', at: [canhoto, y + 1.send(:mm) - linha * 10.5]
    pdf.draw_text 'Sacador/Avalista:', at: [canhoto, y + 0.5.send(:mm) - linha * 12.5]
    pdf.draw_text 'Cód de Baixa', at: [canhoto + 133.send(:mm), y + 0.5.send(:mm) - linha * 12.5]
    pdf.draw_text 'Número do Documento', at: [canhoto + 25.send(:mm), y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text 'Carteira', at: [canhoto + 25.send(:mm), y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text 'Espécie Doc.', at: [canhoto + 50.send(:mm), y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text 'Espécie', at: [canhoto + 50.send(:mm), y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text 'Aceite', at: [canhoto + 74.send(:mm), y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text 'Quantidade', at: [canhoto + 74.send(:mm), y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text 'Data Processamento', at: [canhoto + 98.send(:mm), y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text 'Valor Documento', at: [canhoto + 98.send(:mm), y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text 'Vencimento', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 1.5]
    pdf.draw_text 'Agência/Código Cedente', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 2.5]
    pdf.draw_text 'Cart/Nosso Número', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text '1 (=) Valor do Documento', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text '2 (-) Desconto Abatimento', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 5.5]
    pdf.draw_text '3 (-) Outras Deduções', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 6.5]
    pdf.draw_text '4 (+) Mora / Multa', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 7.5]
    pdf.draw_text '5 (+) Outros Acréscimos', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 8.5]
    pdf.draw_text '6 (+) Valor Cobrado', at: [canhoto + instrucoes + 1.send(:mm), y + 1.send(:mm) - linha * 9.5]

    pdf.draw_text 'Ficha de Compensação', at: [canhoto + 120.send(:mm), y - 85.send(:mm)], style: :bold, size: 8

    #canhoto
    (1..10).each do |i|
      pdf.stroke_horizontal_line 4.send(:mm), canhoto - 4.send(:mm), at: y - linha * i
    end
    pdf.stroke_horizontal_line 4.send(:mm), canhoto - 4.send(:mm), at: y - linha * 15
    pdf.stroke_vertical_line y - linha, y - linha * 2, at: canhoto / 2
    margem_texto = 4.send(:mm)
    pdf.draw_text 'Parcela / Plano', at: [margem_texto, y + 1.send(:mm) - linha * 1.5]
    pdf.draw_text 'Vencimento', at: [canhoto / 2 + 1.send(:mm), y + 1.send(:mm) - linha * 1.5]
    pdf.draw_text 'Agência/Código Cedente', at: [margem_texto, y + 1.send(:mm) - linha * 2.5]
    pdf.draw_text 'Nosso Número', at: [margem_texto, y + 1.send(:mm) - linha * 3.5]
    pdf.draw_text '1 (=) Valor do Documento', at: [margem_texto, y + 1.send(:mm) - linha * 4.5]
    pdf.draw_text '2 (-) Desconto / Abatimento', at: [margem_texto, y + 1.send(:mm) - linha * 5.5]
    pdf.draw_text '3 (-) Outras Deduções', at: [margem_texto, y + 1.send(:mm) - linha * 6.5]
    pdf.draw_text '4 (+) Mora / Multa', at: [margem_texto, y + 1.send(:mm) - linha * 7.5]
    pdf.draw_text '5 (+) Outros Acréscimos', at: [margem_texto, y + 1.send(:mm) - linha * 8.5]
    pdf.draw_text '6 (+) Valor Cobrado', at: [margem_texto, y + 1.send(:mm) - linha * 9.5]
    pdf.draw_text 'Sacado', at: [margem_texto, y + 1.send(:mm) - linha * 10.5]

    pdf.draw_text 'Recibo do Sacado', at: [margem_texto, y + 1.send(:mm) - linha * 15.5], style: :bold
    pdf.draw_text 'autenticar no verso', at: [canhoto / 2 + 4.send(:mm), y + 1.send(:mm) - linha * 15.5], style: :bold, size: 4

    attrs = fatura.boleto_attrs
    margem_direita = canhoto + instrucoes + 1.send(:mm)
    pdf.font_size 8

    # Local de Pagamento 
    if fatura.pix.present?
      local = 'Pagável via QR Code Pix, bancos, canais digitais e lotéricas mesmo após o vencimento.'
    else
      local = 'Pagável em bancos, canais digitais e lotéricas mesmo após o vencimento.'
    end
    pdf.draw_text local, at: [canhoto, y + 1.send(:mm) - linha * 2]
    # Cedente
    pdf.draw_text "#{attrs[:cedente]} - CNPJ: #{attrs[:documento_cedente]}", at: [canhoto, y + 1.send(:mm) - linha * 3]
    # Data Documento
    pdf.draw_text Date.today.strftime("%d/%m/%Y"), at: [canhoto, y + 1.send(:mm) - linha * 4]
    # Número Docuemnto
    pdf.draw_text attrs[:nosso_numero], at: [canhoto + 25.send(:mm), y + 1.send(:mm) - linha * 4]
    # Carteira
    pdf.draw_text fatura.pagamento_perfil.carteira, at: [canhoto + 25.send(:mm), y + 1.send(:mm) - linha * 5]
    # Especie Moeda
    pdf.draw_text 'R$', at: [canhoto + 50.send(:mm), y + 1.send(:mm) - linha * 5]
    # Especie Doc
    pdf.draw_text '26', at: [canhoto + 50.send(:mm), y + 1.send(:mm) - linha * 4]
    # Data Processamento
    pdf.draw_text Date.today.strftime("%d/%m/%Y"), at: [canhoto + 98.send(:mm), y + 1.send(:mm) - linha * 4]
    

    pdf.text_box attrs[:data_vencimento].strftime("%d/%m/%Y"), at: [canhoto+instrucoes, y - linha * 1.5], width: 25.send(:mm), height: linha, align: :right
    pdf.text_box "#{attrs[:agencia]}/#{attrs[:conta_corrente]}", at: [canhoto+instrucoes, y - linha * 2.5], width: 25.send(:mm), height: linha, align: :right
    pdf.text_box  attrs[:nosso_numero], at: [canhoto+instrucoes, y - linha * 3.5], width: 25.send(:mm), height: linha, align: :right
    pdf.text_box  number_to_currency(attrs[:valor], unit: 'R$', separator: ',', delimiter: '.'), at: [canhoto+instrucoes, y - linha * 4.5], width: 25.send(:mm), height: linha, align: :right


    # Sacado
    if attrs[:sacado_documento].length > 14
      documento = 'CNPJ'
    else
      documento = 'CPF'
    end
    pdf.draw_text "#{attrs[:sacado]} - #{documento}: #{attrs[:sacado_documento]}", at: [canhoto, y + 1.send(:mm) - linha * 11]
    pdf.draw_text attrs[:sacado_endereco], at: [canhoto, y + 1.send(:mm) - linha * 11.5]

    # Instruções
    pdf.draw_text attrs[:instrucao1], at: [canhoto, y + 1.send(:mm) - linha * 6]
    pdf.draw_text attrs[:instrucao2], at: [canhoto, y + 1.send(:mm) - linha * 6.75]
    pdf.draw_text attrs[:instrucao3], at: [canhoto, y + 1.send(:mm) - linha * 7.5]
    pdf.draw_text attrs[:instrucao4], at: [canhoto, y + 1.send(:mm) - linha * 8.25]
    pdf.draw_text attrs[:instrucao5], at: [canhoto, y + 1.send(:mm) - linha * 9]
    pdf.draw_text attrs[:instrucao6], at: [canhoto, y + 1.send(:mm) - linha * 9.75]

    # Canhoto
    pdf.draw_text "#{fatura.parcela}/#{fatura.contrato.faturas.count}", at: [margem_texto, y + 1.send(:mm) - linha * 2]
    pdf.text_box attrs[:data_vencimento].strftime("%d/%m/%Y"), at: [margem_texto, y - linha * 1.5], width: canhoto - margem_texto * 2, height: linha, align: :right
    pdf.text_box "#{attrs[:agencia]}/#{attrs[:conta_corrente]}", at: [margem_texto, y - linha * 2.5], width: canhoto - margem_texto * 2, height: linha, align: :right
    pdf.text_box  attrs[:nosso_numero], at: [margem_texto, y - linha * 3.5], width: canhoto - margem_texto * 2, height: linha, align: :right
    pdf.text_box  number_to_currency(attrs[:valor], unit: 'R$', separator: ',', delimiter: '.'), at: [margem_texto, y - linha * 4.5], width: canhoto - margem_texto * 2, height: linha, align: :right
    pdf.text_box  attrs[:sacado], at: [margem_texto, y - linha * 10.5], width: canhoto - margem_texto * 2, height: linha * 2
    pdf.text_box  attrs[:conexao_enderecos], at: [margem_texto, y - linha * 12.5], width: canhoto - margem_texto * 2, height: linha * 3

    if fatura.pix.present?
      pdf.svg fatura.pix_imagem, at: [canhoto + 103.send(:mm), y - 1.send(:mm) - linha * 5], height: 20.send(:mm), width: 20.send(:mm)
      pdf.svg IO.read(Rails.root / 'app' / 'assets' / 'images' / 'pix.svg'), at: [canhoto + 80.send(:mm), y + 1.send(:mm) - linha * 7], width: 18.send(:mm)
    end

    pdf.font_size 11
    pdf.draw_text "#{fatura.pagamento_perfil.banco.to_s.rjust(3, '0')}-#{fatura.pagamento_perfil.banco.to_s.rjust(3, '0').modulo11}", at: [canhoto + 31.send(:mm), y + 1.send(:mm) - linha]
    pdf.font_size 10
    pdf.draw_text fatura.linha_digitavel, at: [canhoto + 45.send(:mm), y + 1.send(:mm) - linha]
    pdf.svg IO.read(Rails.root / 'app' / 'assets' / 'images' / "#{fatura.pagamento_perfil.banco.to_s.rjust(3, '0')}.svg"), at: [margem_texto, y + 1.send(:mm)], width: 28.send(:mm)
    pdf.svg IO.read(Rails.root / 'app' / 'assets' / 'images' / "#{fatura.pagamento_perfil.banco.to_s.rjust(3, '0')}.svg"), at: [canhoto, y + 1.send(:mm)], width: 28.send(:mm)
    pdf.svg fatura.codigo_de_barras_imagem, at: [canhoto , y - linha *13], width: 103.send(:mm)
    contar += 1
  end
end


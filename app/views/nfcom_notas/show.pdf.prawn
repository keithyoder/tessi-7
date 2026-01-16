# app/views/nfcom_notas/show.pdf.prawn
# frozen_string_literal: true

require 'prawn/measurement_extensions'
require 'prawn/qrcode'

prawn_document(page_size: 'A4', margin: [20.mm, 20.mm, 20.mm, 20.mm]) do |pdf|
  pdf.font_families.update('OpenSans' => {
                             normal: Rails.root / 'app/assets/fonts/OpenSans-Regular.ttf',
                             bold: Rails.root / 'app/assets/fonts/OpenSans-ExtraBold.ttf'
                           })
  pdf.font 'OpenSans'

  # Parse XML
  xml = @nfcom_nota.parse_xml
  ns = 'http://www.portalfiscal.inf.br/nfcom'

  numero      = xml.at_xpath('//xmlns:nNFCom', 'xmlns' => ns)&.text || @nfcom_nota.numero
  serie       = xml.at_xpath('//xmlns:serie', 'xmlns' => ns)&.text || @nfcom_nota.serie
  dh_emissao  = xml.at_xpath('//xmlns:dhEmi', 'xmlns' => ns)&.text
  data_emissao = dh_emissao ? DateTime.parse(dh_emissao) : nil
  chave       = xml.at_xpath('//xmlns:chNFCom', 'xmlns' => ns)&.text || @nfcom_nota.chave_acesso
  protocolo   = xml.at_xpath('//xmlns:nProt', 'xmlns' => ns)&.text || @nfcom_nota.protocolo
  cstat       = xml.at_xpath('//xmlns:cStat', 'xmlns' => ns)&.text || ''

  emitente    = xml.at_xpath('//xmlns:emit', 'xmlns' => ns)
  dest        = xml.at_xpath('//xmlns:dest', 'xmlns' => ns)
  itens       = xml.xpath('//xmlns:det', 'xmlns' => ns)

  valor_total = xml.at_xpath('//xmlns:vNF', 'xmlns' => ns)&.text&.to_d || @nfcom_nota.valor_total

  # -------------------
  # Layout rectangles (simplified example)
  # -------------------
  pdf.rectangle [0.mm, 260.mm], 168.mm, 260.mm
  pdf.rectangle [0.mm, 232.mm], 168.mm, 8.mm
  pdf.close_and_stroke

  pdf.text_box "NOTA FISCAL DE SERVIÇO DE COMUNICAÇÃO - MODELO NFCom", size: 14, style: :bold, at: [2.mm, 230.mm]

  # Número / Série / Emissão
  pdf.text_box "Número: #{numero}", size: 12, at: [1.mm, 219.mm], width: 40.mm, align: :right
  pdf.text_box "Série: #{serie}", size: 12, at: [42.mm, 219.mm], width: 40.mm, align: :right
  pdf.text_box "Emissão: #{data_emissao&.strftime('%d/%m/%Y')}", size: 12, at: [126.mm, 219.mm], width: 40.mm, align: :right

  # Emitente
  pdf.text_box "Emitente: #{emitente.at_xpath('xmlns:xNome', 'xmlns' => ns)&.text}", size: 12, at: [2.mm, 195.mm]
  pdf.text_box "CNPJ: #{emitente.at_xpath('xmlns:CNPJ', 'xmlns' => ns)&.text}", size: 12, at: [2.mm, 190.mm]

  # Destinatário
  pdf.text_box "Destinatário: #{dest.at_xpath('xmlns:xNome', 'xmlns' => ns)&.text}", size: 12, at: [2.mm, 180.mm]
  if dest.at_xpath('xmlns:CNPJ', 'xmlns' => ns)
    pdf.text_box "CNPJ: #{dest.at_xpath('xmlns:CNPJ', 'xmlns' => ns)&.text}", size: 12, at: [2.mm, 175.mm]
  else
    pdf.text_box "CPF: #{dest.at_xpath('xmlns:CPF', 'xmlns' => ns)&.text}", size: 12, at: [2.mm, 175.mm]
  end

  # Itens
  y = 158.mm
  itens.each do |item|
    desc = item.at_xpath('xmlns:prod/xmlns:xProd', 'xmlns' => ns)&.text
    vprod = item.at_xpath('xmlns:prod/xmlns:vProd', 'xmlns' => ns)&.text
    pdf.text_box desc, size: 12, at: [2.mm, y], width: 120.mm
    pdf.text_box vprod, size: 12, at: [85.mm, y], width: 26.mm, align: :right
    y -= 12.mm
  end

  # Valor total
  pdf.text_box "Valor Total: #{number_to_currency(valor_total)}", size: 14, style: :bold, at: [126.mm, 10.mm], width: 40.mm, align: :right

  # QR code & chave
  if @nfcom_nota.consulta_url.present?
    qr_code = RQRCode::QRCode.new(@nfcom_nota.consulta_url)
    pdf.render_qr_code(qr_code, pos: [10.mm, 40.mm], extent: 35.mm)
    pdf.text_box "Chave de Acesso: #{chave}", size: 12, at: [1.mm, 10.mm], width: 126.mm, align: :center
  end

  # Observações SEFAZ / Mensagem
  if @nfcom_nota.mensagem_sefaz.present?
    pdf.text_box "Mensagem SEFAZ: #{@nfcom_nota.mensagem_sefaz}", size: 8, at: [2.mm, 15.mm], width: 160.mm
  end
end

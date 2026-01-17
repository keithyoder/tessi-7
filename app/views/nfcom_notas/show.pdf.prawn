# frozen_string_literal: true
# app/views/nfcom_notas/show.pdf.prawn

require 'prawn/measurement_extensions'
require 'prawn/qrcode'

prawn_document(page_size: 'A4', margin: [5.mm, 5.mm, 5.mm, 5.mm]) do |pdf|
  extend DanfeComHelper

  # Setup fonts
  pdf.font_families.update('OpenSans' => {
    normal: Rails.root / 'app/assets/fonts/OpenSans-Regular.ttf',
    bold: Rails.root / 'app/assets/fonts/OpenSans-ExtraBold.ttf'
  })
  pdf.font 'OpenSans'

  # Parse XML
  xml = @nfcom_nota.parse_xml
  ns = 'http://www.portalfiscal.inf.br/nfcom'

  # Extract sections
  ide = xml.at_xpath('//xmlns:ide', 'xmlns' => ns)
  emit = xml.at_xpath('//xmlns:emit', 'xmlns' => ns)
  dest = xml.at_xpath('//xmlns:dest', 'xmlns' => ns)
  total = xml.at_xpath('//xmlns:total', 'xmlns' => ns)
  itens = xml.xpath('//xmlns:det', 'xmlns' => ns)
  gfat = xml.at_xpath('//xmlns:gFat', 'xmlns' => ns)
  assinante = xml.at_xpath('//xmlns:assinante', 'xmlns' => ns)
  prot = xml.at_xpath('//xmlns:protNFCom', 'xmlns' => ns)
  inf_adic = xml.at_xpath('//xmlns:infAdic', 'xmlns' => ns)

  emit_info = extract_emitter_info(emit, ns)
  dest_info = extract_recipient_info(dest, ns)

  crt = emit.at_xpath('xmlns:CRT', 'xmlns' => ns)&.text
  numero = ide.at_xpath('xmlns:nNF', 'xmlns' => ns)&.text
  serie = ide.at_xpath('xmlns:serie', 'xmlns' => ns)&.text
  dh_emissao = ide.at_xpath('xmlns:dhEmi', 'xmlns' => ns)&.text
  tp_amb = ide.at_xpath('xmlns:tpAmb', 'xmlns' => ns)&.text
  fin_nfcom = ide.at_xpath('xmlns:finNFCom', 'xmlns' => ns)&.text

  chave = prot&.at_xpath('xmlns:chNFCom', 'xmlns' => ns)&.text || @nfcom_nota.chave_acesso
  protocolo = prot&.at_xpath('xmlns:nProt', 'xmlns' => ns)&.text || @nfcom_nota.protocolo
  dh_recbto = prot&.at_xpath('xmlns:dhRecbto', 'xmlns' => ns)&.text || @nfcom_nota.data_autorizacao&.iso8601
  c_stat = prot&.at_xpath('xmlns:cStat', 'xmlns' => ns)&.text

  y_pos = pdf.cursor

  logo_path = Rails.root / 'app' / 'assets' / 'images' / 'logo-cores.svg'
  if File.exist?(logo_path)
    pdf.svg IO.read(logo_path), at: [2.mm, y_pos], width: 50.mm
  end

  # ==================== HEADER ====================
  # pdf.fill_color 'CCCCCC'
  # pdf.fill_rectangle [0, y_pos], 200.mm, 10.mm
  pdf.fill_color '000000'
  pdf.text_box 'NOTA FISCAL DE SERVIÇO DE COMUNICAÇÃO',
              at: [55.mm, y_pos - 10.mm],  # shift title right to leave room for logo
              size: 16,
              style: :bold,
              align: :center,
              width: 141.mm  # adjusted width to fit title + logo
  y_pos -= 25.mm

  # ==================== EMITTER & DOCUMENT INFO ====================
  pdf.stroke_rectangle [0, y_pos], 200.mm, 30.mm

  # Emitter info
  pdf.text_box 'EMITENTE', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold
  pdf.text_box emit_info[:nome], at: [2.mm, y_pos - 6.mm], size: 10, style: :bold
  pdf.text_box "CNPJ: #{format_cnpj_cpf(emit_info[:cnpj])}", at: [2.mm, y_pos - 11.mm], size: 10
  pdf.text_box "IE: #{emit_info[:ie]}", at: [2.mm, y_pos - 16.mm], size: 10

  endereco = "#{emit_info[:logradouro]}, #{emit_info[:numero]}"
  endereco += " - #{emit_info[:complemento]}" if emit_info[:complemento].present?
  endereco += " - #{emit_info[:bairro]}" if emit_info[:bairro].present?
  pdf.text_box endereco, at: [2.mm, y_pos - 21.mm], size: 10, width: 120.mm
  pdf.text_box "#{emit_info[:municipio]}/#{emit_info[:uf]} - CEP: #{format_cep(emit_info[:cep])}", 
             at: [2.mm, y_pos - 26.mm], size: 10

  # Document info (right)
  pdf.stroke_vertical_line y_pos, y_pos - 30.mm, at: 130.mm
  pdf.text_box 'NÚMERO', at: [132.mm, y_pos - 2.mm], size: 10, style: :bold
  pdf.text_box numero.to_s.rjust(6, '0'), at: [132.mm, y_pos - 7.mm], size: 14, style: :bold
  pdf.text_box 'SÉRIE', at: [155.mm, y_pos - 2.mm], size: 10, style: :bold
  pdf.text_box serie, at: [155.mm, y_pos - 7.mm], size: 14, style: :bold
  pdf.text_box 'DATA DE EMISSÃO', at: [132.mm, y_pos - 14.mm], size: 10, style: :bold
  pdf.text_box format_datetime_xml(dh_emissao), at: [132.mm, y_pos - 19.mm], size: 10
  pdf.text_box nfcom_tipo_documento(fin_nfcom), at: [132.mm, y_pos - 25.mm], size: 10, style: :bold

  y_pos -= 33.mm

  # ==================== ACCESS KEY & PROTOCOL ====================
  pdf.stroke_rectangle [0, y_pos], 200.mm, 30.mm

  consulta_url = @nfcom_nota.consulta_url
  if consulta_url.present?
    begin
      qr_code = RQRCode::QRCode.new(consulta_url.to_s)
      pdf.render_qr_code(qr_code, pos: [2.mm, y_pos - 2.mm], extent: 26.mm, level: :l)
    rescue StandardError => e
      pdf.stroke_rectangle [2.mm, y_pos - 2.mm], 22.mm, 22.mm
      pdf.text_box 'QR', at: [6.mm, y_pos - 9.mm], size: 10, style: :bold
    end
  else
    pdf.stroke_rectangle [2.mm, y_pos - 2.mm], 22.mm, 22.mm
    pdf.text_box 'QR', at: [6.mm, y_pos - 9.mm], size: 10, style: :bold
  end

  pdf.text_box 'CHAVE DE ACESSO', at: [30.mm, y_pos - 2.mm], size: 10, style: :bold
  pdf.text_box format_chave_acesso(chave), at: [30.mm, y_pos - 7.mm], size: 10, width: 165.mm

  if protocolo.present?
    pdf.text_box 'PROTOCOLO DE AUTORIZAÇÃO', at: [30.mm, y_pos - 13.mm], size: 10, style: :bold
    pdf.text_box "#{protocolo} - #{format_datetime_xml(dh_recbto)}",
                 at: [30.mm, y_pos - 18.mm], size: 10
  end

  pdf.text_box 'Consulte a autenticidade deste documento através do QR Code ou da chave de acesso no site da SEFAZ',
                at: [30.mm, y_pos - 24.mm], size: 8

  y_pos -= 33.mm

  # ==================== RECIPIENT ====================
  pdf.stroke_rectangle [0, y_pos], 200.mm, 28.mm
  pdf.text_box 'DESTINATÁRIO / TOMADOR DO SERVIÇO', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold
  pdf.text_box dest_info[:nome], at: [2.mm, y_pos - 7.mm], size: 12, style: :bold

  dest_doc = dest_info[:cnpj] || dest_info[:cpf]
  doc_label = dest_info[:cnpj] ? 'CNPJ' : 'CPF'
  pdf.text_box "#{doc_label}: #{format_cnpj_cpf(dest_doc)}", at: [2.mm, y_pos - 13.mm], size: 10

  ie_text = case dest_info[:ind_ie_dest]
            when '1' then dest_info[:ie]
            when '2' then 'ISENTO'
            when '9' then 'NÃO CONTRIBUINTE'
            else 'NÃO CONTRIBUINTE'
            end
  pdf.text_box "IE: #{ie_text}", at: [70.mm, y_pos - 13.mm], size: 10

  endereco = "#{dest_info[:logradouro]}, #{dest_info[:numero]}"
  endereco += " - #{dest_info[:complemento]}" if dest_info[:complemento].present?
  pdf.text_box endereco, at: [2.mm, y_pos - 18.mm], size: 10, width: 195.mm

  bairro_cidade_cep = "#{dest_info[:bairro]} - #{dest_info[:municipio]}/#{dest_info[:uf]} - CEP: #{format_cep(dest_info[:cep])}"
  pdf.text_box bairro_cidade_cep, at: [2.mm, y_pos - 23.mm], size: 10

  y_pos -= 32.mm

  # ==================== SUBSCRIBER ====================
  if assinante
    pdf.stroke_rectangle [0, y_pos], 200.mm, 18.mm
    pdf.text_box 'DADOS DO ASSINANTE', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold

    cod_assinante = assinante.at_xpath('xmlns:iCodAssinante', 'xmlns' => ns)&.text
    tipo_servico = assinante.at_xpath('xmlns:tpServUtil', 'xmlns' => ns)&.text
    n_contrato = assinante.at_xpath('xmlns:nContrato', 'xmlns' => ns)&.text

    pdf.text_box "Código: #{cod_assinante}", at: [2.mm, y_pos - 7.mm], size: 10
    pdf.text_box "Tipo: #{nfcom_tipo_servico(tipo_servico)}", at: [55.mm, y_pos - 7.mm], size: 10
    pdf.text_box "Contrato: #{n_contrato}", at: [2.mm, y_pos - 12.mm], size: 10 if n_contrato.present?

    y_pos -= 21.mm
  end

  # ==================== BILLING ====================
  if gfat
    pdf.stroke_rectangle [0, y_pos], 200.mm, 22.mm
    pdf.text_box 'INFORMAÇÕES DE FATURAMENTO', at: [2.mm, y_pos - 2.mm], size: 10, style: :bold

    compet = gfat.at_xpath('xmlns:CompetFat', 'xmlns' => ns)&.text
    d_venc = gfat.at_xpath('xmlns:dVencFat', 'xmlns' => ns)&.text
    d_per_uso_ini = gfat.at_xpath('xmlns:dPerUsoIni', 'xmlns' => ns)&.text
    d_per_uso_fim = gfat.at_xpath('xmlns:dPerUsoFim', 'xmlns' => ns)&.text
    cod_barras = gfat.at_xpath('xmlns:codBarras', 'xmlns' => ns)&.text

    pdf.text_box "Competência: #{format_competencia(compet)}", at: [2.mm, y_pos - 7.mm], size: 10
    pdf.text_box "Vencimento: #{format_date_xml(d_venc)}", at: [55.mm, y_pos - 7.mm], size: 10

    if d_per_uso_ini.present? && d_per_uso_fim.present?
      periodo_texto = "Período de Uso: #{format_date_xml(d_per_uso_ini)} a #{format_date_xml(d_per_uso_fim)}"
      pdf.text_box periodo_texto, at: [120.mm, y_pos - 7.mm], size: 10
    end

    if cod_barras.present?
      pdf.text_box "Código de Barras:", at: [2.mm, y_pos - 13.mm], size: 10
      pdf.text_box format_barcode(cod_barras), at: [2.mm, y_pos - 18.mm], size: 8, width: 195.mm
    end

    y_pos -= 26.mm
  end

  # ==================== ITEMS TABLE ====================
  pdf.move_cursor_to(y_pos)
  pdf.text 'DISCRIMINAÇÃO DOS SERVIÇOS', size: 10, style: :bold
  pdf.move_down 4.mm

  table_data = build_items_table_data(itens, ns)
  pdf.table(table_data,
            header: true,
            width: 200.mm,
            cell_style: { size: 9, padding: [3, 4, 3, 4], border_width: 0.5 }) do |t|
    t.row(0).font_style = :bold
    t.row(0).background_color = 'EEEEEE'
    t.columns(5..8).align = :right
  end

  #pdf.move_down 4.mm

  # ==================== TOTALS ====================
  totals_data = build_totals_table_data(total, ns)
  pdf.float do
    pdf.table(totals_data,
              position: :right,
              width: 75.mm,
              cell_style: { size: 10, padding: [3, 5, 3, 5], border_width: 0.5 },
              column_widths: { 0 => 37.mm, 1 => 38.mm }) do |t|
      t.column(1).align = :right
      t.row(-1).font_style = :bold
      t.row(-1).background_color = 'EEEEEE'
      t.row(-1).size = 11
    end
  end
  pdf.move_down 40.mm

  # ==================== ADDITIONAL INFO ====================
  if inf_adic
    inf_cpl_nodes = inf_adic.xpath('xmlns:infCpl', 'xmlns' => ns)
    if inf_cpl_nodes.any?
      pdf.move_down 3.mm
      pdf.bounding_box([2.mm, pdf.cursor], width: 196.mm) do
        pdf.text 'INFORMAÇÕES COMPLEMENTARES', size: 10, style: :bold, indent_paragraphs: 0.mm
        pdf.move_down 2.mm
        inf_cpl_nodes.each do |node|
          next if node.text.blank?
          pdf.text node.text, size: 10, indent_paragraphs: 0.mm, overflow: :shrink_to_fit
          pdf.move_down 2.mm
        end
      end
      pdf.move_down 3.mm
    end
  end

  # ==================== FOOTER ====================
  pdf.move_down 5.mm

  if c_stat.present?
    status_text = status_message(c_stat)
    color = nfcom_autorizada?(c_stat) ? '006400' : 'FF0000'
    pdf.fill_color color
    pdf.text status_text, size: 11, style: :bold, align: :center
    pdf.fill_color '000000'
    pdf.move_down 3.mm
  end

  if @nfcom_nota.respond_to?(:mensagem_sefaz) && @nfcom_nota.mensagem_sefaz.present?
    pdf.text @nfcom_nota.mensagem_sefaz, size: 10, align: :center
    pdf.move_down 3.mm
  end

  if tp_amb == '2'
    pdf.move_down 3.mm
    pdf.fill_color 'FF0000'
    pdf.bounding_box([0, pdf.cursor], width: pdf.bounds.width) do
      pdf.text 'DOCUMENTO EMITIDO EM AMBIENTE DE HOMOLOGAÇÃO - SEM VALOR FISCAL',
               size: 10, style: :bold, align: :center
    end
    pdf.fill_color '000000'
  end
end

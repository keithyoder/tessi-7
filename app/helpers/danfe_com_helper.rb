# frozen_string_literal: true

module DanfeComHelper
  # Format CNPJ: 12.345.678/0001-90
  def format_cnpj(cnpj)
    return '' unless cnpj

    cnpj = cnpj.gsub(/\D/, '')
    return cnpj unless cnpj.length == 14

    cnpj.gsub(/(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})/, '\1.\2.\3/\4-\5')
  end

  # Format CPF: 123.456.789-01
  def format_cpf(cpf)
    return '' unless cpf

    cpf = cpf.gsub(/\D/, '')
    return cpf unless cpf.length == 11

    cpf.gsub(/(\d{3})(\d{3})(\d{3})(\d{2})/, '\1.\2.\3-\4')
  end

  # Format CNPJ or CPF automatically
  def format_cnpj_cpf(doc)
    return '' unless doc

    doc = doc.gsub(/\D/, '')

    case doc.length
    when 14 then format_cnpj(doc)
    when 11 then format_cpf(doc)
    else doc
    end
  end

  # Format CEP: 12345-678
  def format_cep(cep)
    return '' unless cep

    cep = cep.gsub(/\D/, '')
    return cep unless cep.length == 8

    cep.gsub(/(\d{5})(\d{3})/, '\1-\2')
  end

  # Format access key with spaces: 1234 5678 9012 ...
  def format_chave_acesso(chave)
    return '' unless chave

    chave.to_s.scan(/.{4}/).join(' ')
  end

  # Format competencia (AAAAMM) to MM/AAAA
  def format_competencia(compet)
    return '' unless compet && compet.length == 6

    "#{compet[4..5]}/#{compet[0..3]}"
  end

  # Get NFCom document type description
  def nfcom_tipo_documento(fin_nfcom)
    case fin_nfcom
    when '0' then 'NORMAL'
    when '3' then 'SUBSTITUIÇÃO'
    when '4' then 'AJUSTE'
    else 'NORMAL'
    end
  end

  # Get service type description
  def nfcom_tipo_servico(tipo)
    {
      '1' => 'Telefonia',
      '2' => 'Comunicação de dados',
      '3' => 'TV por Assinatura',
      '4' => 'Provimento de acesso à Internet',
      '5' => 'Multimídia',
      '6' => 'Outros',
      '7' => 'Vários'
    }[tipo] || 'N/A'
  end

  # Get subscriber type description
  def nfcom_tipo_assinante(tipo)
    {
      '1' => 'Comercial',
      '2' => 'Industrial',
      '3' => 'Residencial/Pessoa Física',
      '4' => 'Produtor Rural',
      '5' => 'Órgão Público',
      '6' => 'Prestador de Telecom',
      '7' => 'Diplomático',
      '8' => 'Igreja/Templo',
      '99' => 'Outros'
    }[tipo] || 'N/A'
  end

  # Get unit of measurement description
  def nfcom_unidade_medida(u_med)
    case u_med
    when '1' then 'MIN'
    when '2' then 'MB'
    when '3' then 'GB'
    when '4' then 'UN'
    else u_med
    end
  end

  # Get ICMS CST description
  def icms_cst_descricao(cst)
    {
      '00' => 'Tributação normal',
      '20' => 'Com redução de BC',
      '40' => 'Isenta',
      '41' => 'Não tributada',
      '51' => 'Diferimento',
      '90' => 'Outros'
    }[cst] || cst
  end

  # Extract full address from XML node
  def format_endereco_completo(endereco_node, ns)
    return '' unless endereco_node

    logr = endereco_node.at_xpath('xmlns:xLgr', 'xmlns' => ns)&.text
    nro = endereco_node.at_xpath('xmlns:nro', 'xmlns' => ns)&.text
    compl = endereco_node.at_xpath('xmlns:xCpl', 'xmlns' => ns)&.text
    bairro = endereco_node.at_xpath('xmlns:xBairro', 'xmlns' => ns)&.text
    mun = endereco_node.at_xpath('xmlns:xMun', 'xmlns' => ns)&.text
    uf = endereco_node.at_xpath('xmlns:UF', 'xmlns' => ns)&.text
    cep = endereco_node.at_xpath('xmlns:CEP', 'xmlns' => ns)&.text

    parts = []
    parts << "#{logr}, #{nro}" if logr && nro
    parts << compl if compl.present?
    parts << bairro if bairro
    parts << "#{mun}/#{uf}" if mun && uf
    parts << "CEP: #{format_cep(cep)}" if cep

    parts.join(' - ')
  end

  # Build cidade/UF string
  def format_cidade_uf(endereco_node, ns)
    return '' unless endereco_node

    mun = endereco_node.at_xpath('xmlns:xMun', 'xmlns' => ns)&.text
    uf = endereco_node.at_xpath('xmlns:UF', 'xmlns' => ns)&.text

    "#{mun}/#{uf}" if mun && uf
  end

  # Draw a labeled box in PDF
  def draw_labeled_box(pdf, x, y, width, height, label, content, label_size: 6, content_size: 8)
    pdf.stroke_rectangle [x, y], width, height

    if label
      pdf.fill_color '000000'
      pdf.text_box label,
                   at: [x + 1.mm, y - 1.mm],
                   size: label_size,
                   style: :bold,
                   width: width - 2.mm
    end

    return unless content

    pdf.text_box content,
                 at: [x + 1.mm, y - (label_size + 2).mm],
                 size: content_size,
                 width: width - 2.mm
  end

  # Create items table data array
  def build_items_table_data(itens, ns)
    data = []
    data << ['Item', 'Código', 'Descrição', 'Class.', 'Unid.', 'Qtd', 'Vlr Unit', 'Desconto', 'Vlr Total']

    itens.each_with_index do |item, idx|
      prod = item.at_xpath('xmlns:prod', 'xmlns' => ns)
      next unless prod

      n_item = (idx + 1).to_s
      c_prod = prod.at_xpath('xmlns:cProd', 'xmlns' => ns)&.text
      x_prod = prod.at_xpath('xmlns:xProd', 'xmlns' => ns)&.text
      c_class = prod.at_xpath('xmlns:cClass', 'xmlns' => ns)&.text
      u_med = prod.at_xpath('xmlns:uMed', 'xmlns' => ns)&.text
      q_fat = prod.at_xpath('xmlns:qFaturada', 'xmlns' => ns)&.text
      v_item = prod.at_xpath('xmlns:vItem', 'xmlns' => ns)&.text
      v_desc = prod.at_xpath('xmlns:vDesc', 'xmlns' => ns)&.text
      v_prod = prod.at_xpath('xmlns:vProd', 'xmlns' => ns)&.text

      data << [
        n_item,
        c_prod || '',
        x_prod || '',
        c_class || '',
        nfcom_unidade_medida(u_med),
        number_with_precision(q_fat.to_f, precision: 2),
        number_to_currency(v_item.to_f),
        v_desc.present? ? number_to_currency(v_desc.to_f) : '-',
        number_to_currency(v_prod.to_f)
      ]
    end

    data
  end

  # Create totals table data array
  def build_totals_table_data(total, ns)
    icms_tot = total.at_xpath('xmlns:ICMSTot', 'xmlns' => ns)

    [
      ['BC ICMS', number_to_currency(icms_tot.at_xpath('xmlns:vBC', 'xmlns' => ns)&.text.to_f)],
      ['ICMS', number_to_currency(icms_tot.at_xpath('xmlns:vICMS', 'xmlns' => ns)&.text.to_f)],
      ['PIS', number_to_currency(total.at_xpath('xmlns:vPIS', 'xmlns' => ns)&.text.to_f)],
      ['COFINS', number_to_currency(total.at_xpath('xmlns:vCOFINS', 'xmlns' => ns)&.text.to_f)],
      ['Desconto', number_to_currency(total.at_xpath('xmlns:vDesc', 'xmlns' => ns)&.text.to_f)],
      ['VALOR TOTAL', number_to_currency(total.at_xpath('xmlns:vNF', 'xmlns' => ns)&.text.to_f)]
    ]
  end

  # Get ambiente description
  def ambiente_descricao(tp_amb)
    case tp_amb
    when '1' then 'PRODUÇÃO'
    when '2' then 'HOMOLOGAÇÃO'
    else 'DESCONHECIDO'
    end
  end

  # Get tipo emissao description
  def tipo_emissao_descricao(tp_emis)
    case tp_emis
    when '1' then 'Normal'
    when '2' then 'Contingência'
    else 'Normal'
    end
  end

  # Safe XML text extraction
  def safe_xml_text(node, xpath, namespace)
    return '' unless node

    node.at_xpath(xpath, 'xmlns' => namespace)&.text || ''
  end

  # Format phone number
  def format_telefone(fone)
    return '' unless fone

    fone = fone.gsub(/\D/, '')

    case fone.length
    when 10
      # (11) 1234-5678
      fone.gsub(/(\d{2})(\d{4})(\d{4})/, '(\1) \2-\3')
    when 11
      # (11) 91234-5678
      fone.gsub(/(\d{2})(\d{5})(\d{4})/, '(\1) \2-\3')
    else
      fone
    end
  end

  # Get PIS/COFINS CST description
  def pis_cofins_cst_descricao(cst)
    {
      '01' => 'Tributável com alíquota básica',
      '02' => 'Tributável com alíquota diferenciada',
      '06' => 'Tributável com alíquota zero',
      '07' => 'Operação isenta',
      '08' => 'Operação sem incidência',
      '09' => 'Operação com suspensão',
      '49' => 'Outras operações'
    }[cst] || cst
  end

  # Format decimal value
  def format_decimal(value, precision = 2)
    return '0,00' unless value

    number_with_precision(value.to_f, precision: precision, delimiter: '.', separator: ',')
  end

  # Extract emitter full info
  def extract_emitter_info(emit, ns)
    return {} unless emit

    {
      cnpj: emit.at_xpath('xmlns:CNPJ', 'xmlns' => ns)&.text,
      ie: emit.at_xpath('xmlns:IE', 'xmlns' => ns)&.text,
      nome: emit.at_xpath('xmlns:xNome', 'xmlns' => ns)&.text,
      fantasia: emit.at_xpath('xmlns:xFant', 'xmlns' => ns)&.text,
      logradouro: emit.at_xpath('xmlns:enderEmit/xmlns:xLgr', 'xmlns' => ns)&.text,
      numero: emit.at_xpath('xmlns:enderEmit/xmlns:nro', 'xmlns' => ns)&.text,
      complemento: emit.at_xpath('xmlns:enderEmit/xmlns:xCpl', 'xmlns' => ns)&.text,
      bairro: emit.at_xpath('xmlns:enderEmit/xmlns:xBairro', 'xmlns' => ns)&.text,
      municipio: emit.at_xpath('xmlns:enderEmit/xmlns:xMun', 'xmlns' => ns)&.text,
      uf: emit.at_xpath('xmlns:enderEmit/xmlns:UF', 'xmlns' => ns)&.text,
      cep: emit.at_xpath('xmlns:enderEmit/xmlns:CEP', 'xmlns' => ns)&.text,
      telefone: emit.at_xpath('xmlns:enderEmit/xmlns:fone', 'xmlns' => ns)&.text,
      email: emit.at_xpath('xmlns:enderEmit/xmlns:email', 'xmlns' => ns)&.text
    }
  end

  # Extract recipient full info
  def extract_recipient_info(dest, ns)
    return {} unless dest

    {
      nome: dest.at_xpath('xmlns:xNome', 'xmlns' => ns)&.text,
      cnpj: dest.at_xpath('xmlns:CNPJ', 'xmlns' => ns)&.text,
      cpf: dest.at_xpath('xmlns:CPF', 'xmlns' => ns)&.text,
      ie: dest.at_xpath('xmlns:IE', 'xmlns' => ns)&.text,
      ind_ie_dest: dest.at_xpath('xmlns:indIEDest', 'xmlns' => ns)&.text,
      logradouro: dest.at_xpath('xmlns:enderDest/xmlns:xLgr', 'xmlns' => ns)&.text,
      numero: dest.at_xpath('xmlns:enderDest/xmlns:nro', 'xmlns' => ns)&.text,
      complemento: dest.at_xpath('xmlns:enderDest/xmlns:xCpl', 'xmlns' => ns)&.text,
      bairro: dest.at_xpath('xmlns:enderDest/xmlns:xBairro', 'xmlns' => ns)&.text,
      municipio: dest.at_xpath('xmlns:enderDest/xmlns:xMun', 'xmlns' => ns)&.text,
      uf: dest.at_xpath('xmlns:enderDest/xmlns:UF', 'xmlns' => ns)&.text,
      cep: dest.at_xpath('xmlns:enderDest/xmlns:CEP', 'xmlns' => ns)&.text,
      telefone: dest.at_xpath('xmlns:enderDest/xmlns:fone', 'xmlns' => ns)&.text,
      email: dest.at_xpath('xmlns:enderDest/xmlns:email', 'xmlns' => ns)&.text
    }
  end

  # Get status message based on cStat code
  def status_message(c_stat)
    case c_stat
    when '100' then 'Autorizado o uso da NFCom'
    when '101' then 'Cancelamento homologado'
    when '102' then 'Inutilização homologada'
    when '107' then 'Serviço em Operação'
    when '110' then 'Uso Denegado'
    when '150' then 'Autorizado fora de prazo'
    when '301' then 'Uso Denegado - Irregularidade fiscal do emitente'
    when '302' then 'Uso Denegado - Irregularidade fiscal do destinatário'
    else "Status #{c_stat}"
    end
  end

  # Check if authorized
  def nfcom_autorizada?(c_stat)
    %w[100 150].include?(c_stat)
  end

  # Check if cancelled
  def nfcom_cancelada?(c_stat)
    ['101'].include?(c_stat)
  end

  # Check if denied
  def nfcom_denegada?(c_stat)
    %w[110 301 302].include?(c_stat)
  end

  # Format datetime from XML
  def format_datetime_xml(datetime_str, format = '%d/%m/%Y %H:%M')
    return '' unless datetime_str

    DateTime.parse(datetime_str).strftime(format)
  rescue ArgumentError
    datetime_str
  end

  # Format date from XML
  def format_date_xml(date_str, format = '%d/%m/%Y')
    return '' unless date_str

    Date.parse(date_str).strftime(format)
  rescue ArgumentError
    date_str
  end

  # Extract tax info from item
  def extract_item_tax_info(item, ns)
    imposto = item.at_xpath('xmlns:imposto', 'xmlns' => ns)
    return {} unless imposto

    icms_node = imposto.at_xpath('xmlns:ICMS00 | xmlns:ICMS20 | xmlns:ICMS40 | xmlns:ICMS51 | xmlns:ICMS90',
                                 'xmlns' => ns)
    pis = imposto.at_xpath('xmlns:PIS', 'xmlns' => ns)
    cofins = imposto.at_xpath('xmlns:COFINS', 'xmlns' => ns)

    {
      icms_cst: icms_node&.at_xpath('xmlns:CST', 'xmlns' => ns)&.text,
      icms_bc: icms_node&.at_xpath('xmlns:vBC', 'xmlns' => ns)&.text,
      icms_aliq: icms_node&.at_xpath('xmlns:pICMS', 'xmlns' => ns)&.text,
      icms_valor: icms_node&.at_xpath('xmlns:vICMS', 'xmlns' => ns)&.text,
      pis_cst: pis&.at_xpath('xmlns:CST', 'xmlns' => ns)&.text,
      pis_bc: pis&.at_xpath('xmlns:vBC', 'xmlns' => ns)&.text,
      pis_aliq: pis&.at_xpath('xmlns:pPIS', 'xmlns' => ns)&.text,
      pis_valor: pis&.at_xpath('xmlns:vPIS', 'xmlns' => ns)&.text,
      cofins_cst: cofins&.at_xpath('xmlns:CST', 'xmlns' => ns)&.text,
      cofins_bc: cofins&.at_xpath('xmlns:vBC', 'xmlns' => ns)&.text,
      cofins_aliq: cofins&.at_xpath('xmlns:pCOFINS', 'xmlns' => ns)&.text,
      cofins_valor: cofins&.at_xpath('xmlns:vCOFINS', 'xmlns' => ns)&.text
    }
  end

  # Get CFOP description (simplified - you can expand this)
  def cfop_descricao(cfop)
    cfop_map = {
      '5307' => 'Prestação de serviço de comunicação - dentro do estado',
      '5656' => 'Prestação de serviço de comunicação - não tributada',
      '6307' => 'Prestação de serviço de comunicação - fora do estado'
    }
    cfop_map[cfop] || cfop
  end

  # Validate if barcode is present and valid
  def valid_barcode?(cod_barras)
    cod_barras.present? && cod_barras.length.between?(1, 48)
  end

  # Format barcode for display (add spaces for readability)
  def format_barcode(cod_barras)
    return '' unless cod_barras

    # Format typical Brazilian barcode: 5 5 5 6 5 6 1 14
    if [47, 48].include?(cod_barras.length)
      parts = [
        cod_barras[0..4],
        cod_barras[5..9],
        cod_barras[10..14],
        cod_barras[15..20],
        cod_barras[21..25],
        cod_barras[26..31],
        cod_barras[32],
        cod_barras[33..]
      ]
      parts.join(' ')
    else
      cod_barras
    end
  end
end

# frozen_string_literal: true

class Nfcom::Emitter
  def initialize(client: Nfcom::Client.new)
    @client = client
  end

  # Emit a NFCom for a given fatura_id
  # Returns the Nfcom record (with status: 'authorized' or 'rejected')
  def emitir(fatura_id)
    fatura = Fatura.includes(:contrato, :pessoa).find(fatura_id)
    
    # Create DB record first (reserves numero)
    nfcom_record = criar_registro(fatura)
    
    # Build gem Nota object
    nota = build_nota(
      nfcom_record: nfcom_record,
      fatura: fatura,
      contrato: fatura.contrato,
      pessoa: fatura.pessoa
    )
    
    # Send to SEFAZ
    resultado = @client.autorizar(nota)
    
    # Update record based on result
    if resultado[:autorizada]
      nfcom_record.autorizar!(
        protocolo: nota.protocolo,
        chave: nota.chave_acesso,
        xml: nota.xml_autorizado
      )
    else
      nfcom_record&.rejeitar!("#{e.codigo}: #{e.motivo}")
    end
    
    nfcom_record
  rescue Nfcom::Errors::NotaRejeitada => e
    nfcom_record&.rejeitar!("#{e.codigo}: #{e.motivo}")
    raise
  rescue StandardError => e
    nfcom_record&.rejeitar!("Erro: #{e.message}")
    raise
  end

  private

  def criar_registro(fatura)
    NfcomNota.create!(
      fatura: fatura,
      serie: 1,
      numero: NfcomNota.proximo_numero(1), # Auto-increment
      competencia: Date.parse("#{fatura.liquidacao.strftime('%Y-%m')}-01"),
      valor_total: fatura.base_calculo_icms,
      status: 'pending'
    )
  end

  def build_nota(nfcom_record:, fatura:, contrato:, pessoa:)
    nota = Nfcom::Models::Nota.new
    
    # Use numero from database
    nota.numero = nfcom_record.numero
    nota.serie = nfcom_record.serie
    
    # Fixed: use symbols, not integers
    nota.tipo_emissao = :normal
    nota.finalidade = :normal
    nota.data_emissao = Time.current

    # Emitente
    nota.emitente = build_emitente
    
    # Destinatário
    nota.destinatario = build_destinatario(pessoa)
    
    # Assinante
    nota.assinante = build_assinante(pessoa, contrato)
    
    # Fatura
    nota.fatura = build_fatura(fatura)
    
    # Item
    add_item(nota, fatura, contrato)
    
    # Recalculate totals
    nota.recalcular_totais
    
    nota
  end

  def build_emitente
    config = Nfcom.configuration

    emitente = Nfcom::Models::Emitente.new(
      cnpj: config.cnpj,
      inscricao_estadual: config.inscricao_estadual,
      regime_tributario: config.regime_tributario.to_sym,
      razao_social: config.razao_social,
      nome_fantasia: 'Tessi Telecom'
    )

    municipio = Cidade.find_by(nome: 'Pesqueira')
    emitente.endereco = Nfcom::Models::Endereco.new(
      logradouro: 'Rua Treze de Maio',
      numero: '5',
      bairro: 'Centro',
      codigo_municipio: municipio.ibge,
      municipio: municipio.nome,
      uf: municipio.estado.sigla,
      cep: '55200000'
    )
    
    emitente
  end

  def build_destinatario(pessoa)
    destinatario_attrs = if pessoa.pessoa_juridica?
      {
        cnpj: pessoa.cnpj,
        razao_social: pessoa.nome_sem_acentos,
        email: pessoa.email,
        inscricao_estadual: pessoa.ie
      }
    else
      {
        cpf: pessoa.cpf,
        razao_social: pessoa.nome_sem_acentos,
        email: pessoa.email
      }
    end

    destinatario = Nfcom::Models::Destinatario.new(destinatario_attrs)
    destinatario.endereco = Nfcom::Models::Endereco.new(
      logradouro: pessoa.logradouro.nome,
      numero: pessoa.numero,
      bairro: pessoa.bairro.nome,
      codigo_municipio: pessoa.cidade.ibge,
      municipio: pessoa.cidade.nome,
      uf: pessoa.estado.sigla,
      cep: pessoa.logradouro.cep
    )
    
    destinatario
  end

  def build_assinante(pessoa, contrato)
    Nfcom::Models::Assinante.new(
      codigo: pessoa.id.to_s,
      tipo: pessoa.pessoa_juridica? ?
        Nfcom::Models::Assinante::TIPO_COMERCIAL :
        Nfcom::Models::Assinante::TIPO_RESIDENCIAL,
      tipo_servico: Nfcom::Models::Assinante::SERVICO_INTERNET,
      numero_contrato: contrato.id.to_s,
      data_inicio_contrato: contrato.adesao,
      data_fim_contrato: contrato.cancelamento
    )
  end

  def build_fatura(fatura)
    Nfcom::Models::Fatura.new(
      competencia: fatura.liquidacao.strftime('%Y-%m'), # Accepts "YYYY-MM"
      data_vencimento: fatura.vencimento,
      valor_fatura: fatura.base_calculo_icms,
      codigo_barras: fatura.codigo_de_barras
    )
  end

  def add_item(nota, fatura, contrato)
    nota.add_item(
      codigo_servico: '0303',
      descricao: contrato.descricao,
      classe_consumo: :assinatura_multimidia,
      cfop: fatura.cfop,
      unidade: :un,
      quantidade: 1.0,
      valor_unitario: fatura.base_calculo_icms
    )
  end
end
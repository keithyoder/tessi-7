# frozen_string_literal: true

module Nfcom
  class Emitter
    PUBLIC_KEYWORDS = ['fundo municipal'].freeze

    def initialize(client: Nfcom::Client.new)
      @client = client
    end

    # Emit a NFCom for a given fatura_id
    # Returns the NfcomNota record (with status: 'authorized' or 'rejected')
    def emitir(fatura_id)
      fatura = Fatura.com_associacoes.find(fatura_id)

      corrigir_juros_desconto(fatura)

      # Create DB record first (reserves numero)
      nfcom_record = criar_registro(fatura)

      # Build gem Nota object
      nota = build_nota(
        nfcom_record: nfcom_record,
        fatura: fatura,
        contrato: fatura.contrato,
        pessoa: fatura.contrato.pessoa
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
        nfcom_record&.rejeitar!(resultado[:mensagem_sefaz].to_s)
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
      competencia_date = fatura.liquidacao || fatura.vencimento

      # Ensure unpaid faturas are in the current month
      if fatura.valor_liquidacao.blank? &&
         (competencia_date.month != Date.current.month || competencia_date.year != Date.current.year)
        raise 'Não é possível emitir NF para Faturas não pagas fora do mês corrente'
      end

      NfcomNota.create!(
        fatura: fatura,
        serie: 1,
        numero: NfcomNota.proximo_numero(1),
        competencia: Date.parse("#{competencia_date.strftime('%Y-%m')}-01"),
        valor_total: fatura.base_calculo_icms,
        status: 'pending'
      )
    end

    def build_nota(nfcom_record:, fatura:, contrato:, pessoa:)
      nota = Nfcom::Models::Nota.new

      nota.numero = nfcom_record.numero
      nota.serie = nfcom_record.serie
      nota.tipo_emissao = :normal
      nota.finalidade = :normal
      nota.data_emissao = Time.current

      nota.emitente = build_emitente
      nota.destinatario = build_destinatario(pessoa)
      nota.assinante = build_assinante(pessoa, contrato)
      nota.fatura = build_fatura(fatura)
      add_item(nota, fatura, contrato)

      nota.recalcular_totais
      nota.informacoes_adicionais = build_informacoes_adicionais(fatura)

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

      emitente.endereco = Nfcom::Models::Endereco.new(
        logradouro: 'Rua Treze de Maio',
        numero: '5',
        bairro: 'Centro',
        codigo_municipio: 2_610_905,
        municipio: 'Pesqueira',
        uf: 'PE',
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

      logradouro = pessoa.logradouro
      bairro = logradouro.bairro
      cidade = bairro.cidade
      estado = cidade.estado

      destinatario.endereco = Nfcom::Models::Endereco.new(
        logradouro: logradouro.nome,
        numero: pessoa.numero.presence || 0,
        bairro: bairro.nome,
        codigo_municipio: cidade.ibge,
        municipio: cidade.nome,
        uf: estado.sigla,
        cep: logradouro.cep
      )

      destinatario
    end

    def build_assinante(pessoa, contrato)
      tipo = if PUBLIC_KEYWORDS.any? { |kw| pessoa.nome.downcase.include?(kw.downcase) }
               Nfcom::Models::Assinante::TIPO_ORGAO_PUBLICO
             elsif pessoa.pessoa_juridica?
               Nfcom::Models::Assinante::TIPO_COMERCIAL
             else
               Nfcom::Models::Assinante::TIPO_RESIDENCIAL
             end

      Nfcom::Models::Assinante.new(
        codigo: pessoa.id.to_s,
        tipo: tipo,
        tipo_servico: Nfcom::Models::Assinante::SERVICO_INTERNET,
        numero_contrato: contrato.id.to_s,
        data_inicio_contrato: contrato.adesao,
        data_fim_contrato: contrato.cancelamento
      )
    end

    def build_fatura(fatura)
      competencia_date = fatura.liquidacao || fatura.vencimento

      Nfcom::Models::Fatura.new(
        competencia: competencia_date.strftime('%Y-%m'),
        data_vencimento: fatura.vencimento,
        valor_fatura: fatura.base_calculo_icms,
        codigo_barras: fatura.codigo_de_barras,
        periodo_uso_inicio: fatura.periodo_inicio,
        periodo_uso_fim: fatura.periodo_fim
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

    def build_informacoes_adicionais(fatura)
      info = []

      if fatura.contrato.endereco_instalacao_diferente?
        info << 'Endereço de Instalação:'
        fatura.contrato.enderecos.each do |endereco|
          info << "  #{endereco}"
        end
      end

      info << 'Documento emitido por ME ou EPP optante pelo Simples Nacional.'
      info << 'Não gera direito a crédito fiscal de IPI.'
      info << 'Valor aproximado dos Tributos: Federal 13,45%, Municipal 2,00%. Fonte: IBPT (Lei 12.741/2012)'

      info.join("\n")
    end

    def corrigir_juros_desconto(fatura)
      return if fatura.valor_liquidacao.blank?
      return unless fatura.valor_liquidacao < fatura.valor
      return unless fatura.juros_recebidos.to_f.positive?

      desconto_real = fatura.valor - fatura.valor_liquidacao

      Rails.logger.warn '=' * 60
      Rails.logger.warn "CORREÇÃO AUTOMÁTICA - Fatura ##{fatura.id}"
      Rails.logger.warn "  Valor original: R$ #{fatura.valor}"
      Rails.logger.warn "  Valor pago: R$ #{fatura.valor_liquidacao}"
      Rails.logger.warn "  Juros incorretos: R$ #{fatura.juros_recebidos}"
      Rails.logger.warn "  Desconto anterior: R$ #{fatura.desconto_concedido || 0}"
      Rails.logger.warn "  Base ICMS antes: R$ #{fatura.base_calculo_icms}"

      fatura.update_columns(
        juros_recebidos: 0,
        desconto_concedido: desconto_real
      )

      fatura.reload

      Rails.logger.warn "  Desconto corrigido: R$ #{fatura.desconto_concedido}"
      Rails.logger.warn "  Base ICMS depois: R$ #{fatura.base_calculo_icms}"
      Rails.logger.warn '=' * 60
    end
  end
end

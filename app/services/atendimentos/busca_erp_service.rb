# frozen_string_literal: true

class Atendimentos::BuscaErpService
  def self.call(cpf)
    new(cpf).call
  end

  def initialize(cpf)
    @cpf = cpf.to_s.gsub(/\D/, '')
  end

  def call
    pessoa = encontrar_pessoa
    return nil if pessoa.nil?

    conexoes = carregar_conexoes(pessoa)
    return nil if conexoes.empty?

    mapa_vizinhos = construir_mapa_vizinhos(conexoes)

    todas_ids      = (conexoes.map(&:id) + mapa_vizinhos[:todos_ids]).uniq
    todas_conexoes = Conexao.where(id: todas_ids).select(:id, :usuario, :ponto_id)
    status_online  = Conexao.status_conexoes(todas_conexoes)

    {
      cliente: serializar_cliente(pessoa),
      conexoes: serializar_conexoes(conexoes, status_online, mapa_vizinhos)
    }
  end

  private

  CAUSAS_PROBLEMA      = %w[Lost-Carrier Lost-Service NAS-Reboot NAS-Error Admin-Reset].freeze
  DURACAO_MAXIMA_HORAS = 30

  def encontrar_pessoa
    Pessoa.find_by(cpf: cpf_formatado) ||
      Pessoa.find_by(cnpj: cpf_formatado)
  end

  def cpf_formatado
    return @cpf if @cpf.length != 11 && @cpf.length != 14

    if @cpf.length == 11
      "#{@cpf[0..2]}.#{@cpf[3..5]}.#{@cpf[6..8]}-#{@cpf[9..10]}"
    else
      "#{@cpf[0..1]}.#{@cpf[2..4]}.#{@cpf[5..7]}/#{@cpf[8..11]}-#{@cpf[12..13]}"
    end
  end

  def carregar_conexoes(pessoa)
    pessoa.conexoes
      .includes(
        :plano,
        :ponto,
        { caixa: :fibra_rede },
        { contrato: :faturas },
        { logradouro: { bairro: { cidade: :estado } } },
        { pessoa: { logradouro: { bairro: { cidade: :estado } } } }
      )
      .order(:id)
  end

  def construir_mapa_vizinhos(conexoes)
    fibra = conexoes.select { |c| c.ponto&.tecnologia_Fibra? }
    radio = conexoes.select { |c| c.ponto&.tecnologia_Radio? }

    mapa = { caixa: {}, rede: {}, ponto: {}, todos_ids: [] }

    if fibra.any?
      caixa_ids = fibra.map(&:caixa_id).compact.uniq
      rede_ids  = fibra.map { |c| c.caixa&.fibra_rede_id }.compact.uniq

      caixas_por_rede = FibraCaixa
        .where(fibra_rede_id: rede_ids)
        .pluck(:id, :fibra_rede_id)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) do |(caixa_id, rede_id), h|
          h[rede_id] << caixa_id
        end

      todas_caixa_ids = (caixa_ids + caixas_por_rede.values.flatten).uniq

      vizinhos_por_caixa = Conexao
        .where(caixa_id: todas_caixa_ids)
        .pluck(:id, :caixa_id)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) do |(conn_id, caixa_id), h|
          h[caixa_id] << conn_id
        end

      vizinhos_por_rede = caixas_por_rede.transform_values do |ids_caixa|
        ids_caixa.flat_map { |id| vizinhos_por_caixa[id] }
      end

      mapa[:caixa]      = vizinhos_por_caixa
      mapa[:rede]       = vizinhos_por_rede
      mapa[:todos_ids] += (vizinhos_por_caixa.values.flatten + vizinhos_por_rede.values.flatten)
    end

    if radio.any?
      ponto_ids = radio.map(&:ponto_id).compact.uniq

      vizinhos_por_ponto = Conexao
        .where(ponto_id: ponto_ids)
        .pluck(:id, :ponto_id)
        .each_with_object(Hash.new { |h, k| h[k] = [] }) do |(conn_id, ponto_id), h|
          h[ponto_id] << conn_id
        end

      mapa[:ponto]      = vizinhos_por_ponto
      mapa[:todos_ids] += vizinhos_por_ponto.values.flatten
    end

    mapa[:todos_ids] = mapa[:todos_ids].uniq
    mapa
  end

  def serializar_cliente(pessoa)
    {
      nome: pessoa.nome,
      cpf: pessoa.cpf_cnpj_formatado,
      tipo: pessoa.pessoa_fisica? ? 'PF' : 'PJ'
    }
  end

  def serializar_conexoes(conexoes, status_online, mapa_vizinhos)
    conexoes.map do |conexao|
      fibra   = conexao.ponto&.tecnologia_Fibra?
      faturas = conexao.contrato&.faturas || []

      if fibra
        vizinhos_proximos     = contar_vizinhos(mapa_vizinhos[:caixa][conexao.caixa_id], status_online)
        vizinhos_amplos       = contar_vizinhos(mapa_vizinhos[:rede][conexao.caixa&.fibra_rede_id], status_online)
        vizinhos_label        = 'Caixa'
        vizinhos_amplos_label = 'Rede'
        referencia_id         = conexao.caixa&.nome || conexao.caixa_id&.to_s
      else
        vizinhos_proximos     = contar_vizinhos(mapa_vizinhos[:ponto][conexao.ponto_id], status_online)
        vizinhos_amplos       = vizinhos_proximos
        vizinhos_label        = 'Ponto'
        vizinhos_amplos_label = 'Ponto'
        referencia_id         = conexao.ponto&.nome
      end

      {
        id: conexao.id,
        usuario: conexao.usuario,
        contrato_id: conexao.contrato_id,
        endereco: conexao.endereco,
        plano: conexao.plano.nome,
        tecnologia: conexao.ponto&.tecnologia || 'desconhecida',
        status: conexao.bloqueado ? 'bloqueado' : 'ativo',
        inadimplente: conexao.inadimplente?,
        faturas_abertas: serializar_faturas_vencidas(faturas),
        proxima_fatura: serializar_proxima_fatura(faturas),
        trust_release_usado: trust_release_usado?(conexao, faturas),
        roteador_online: status_online[conexao.id] || false,
        referencia_id: referencia_id,
        vizinhos_label: vizinhos_label,
        vizinhos_proximos_online: vizinhos_proximos[:online],
        vizinhos_proximos_total: vizinhos_proximos[:total],
        vizinhos_amplos_label: vizinhos_amplos_label,
        vizinhos_amplos_online: vizinhos_amplos[:online],
        vizinhos_amplos_total: vizinhos_amplos[:total],
        historico_sessoes: historico_sessoes(conexao),
        ping: ping_conexao(conexao)
      }
    end
  end

  def contar_vizinhos(ids, status_online)
    return { online: 0, total: 0 } if ids.blank?

    { total: ids.count, online: ids.count { |id| status_online[id] } }
  end

  def serializar_faturas_vencidas(faturas)
    faturas
      .select { |f| f.liquidacao.nil? && f.cancelamento.nil? && f.vencimento < Date.current }
      .sort_by(&:vencimento)
      .map { |f| serializar_fatura(f) }
  end

  def serializar_proxima_fatura(faturas)
    fatura = faturas
      .select { |f| f.liquidacao.nil? && f.cancelamento.nil? && f.vencimento >= Date.current }
      .min_by(&:vencimento)

    return nil if fatura.nil?

    serializar_fatura(fatura)
  end

  def serializar_fatura(fatura)
    {
      vencimento: fatura.vencimento.strftime('%d/%m/%Y'),
      valor: "R$ #{format('%.2f', fatura.valor).tr('.', ',')}",
      link: fatura.link,
      pix: fatura.pix
    }
  end

  def trust_release_usado?(conexao, faturas)
    return false if conexao.contrato.nil?

    primeira_em_aberto = faturas
      .select { |f| f.liquidacao.nil? && f.cancelamento.nil? }
      .min_by(&:vencimento)

    return false if primeira_em_aberto.nil?

    Atendimento.joins(:detalhes)
      .where(
        pessoa: conexao.pessoa,
        fechamento: primeira_em_aberto.vencimento..
      )
      .where(atendimento_detalhes: { descricao: 'Acesso Liberado' })
      .exists?
  end

  def ping_conexao(conexao)
    return { acessivel: false, erro: 'IP não configurado' } if conexao.ip.blank?

    Atendimentos::PingService.call(conexao.ip)
  end

  def historico_sessoes(conexao)
    return sessoes_vazias if conexao.usuario.blank?

    sessoes = RadAcct
      .where.not(username: nil)
      .where(username: conexao.usuario)
      .where('acctstarttime > ?', 7.days.ago)
      .order(acctstarttime: :desc)
      .pluck(
        :acctstarttime,
        :acctstoptime,
        :acctterminatecause,
        :acctinputoctets,
        :acctoutputoctets
      )

    return sessoes_vazias if sessoes.empty?

    sessoes_validas = sessoes.reject do |start, stop, _, _, _|
      stop.present? && (stop < start || (stop - start) > DURACAO_MAXIMA_HORAS.hours)
    end

    sessao_atual = sessoes_validas.find { |_, stop, _, _, _| stop.nil? }

    quedas = sessoes_validas.select do |_, stop, causa, _, _|
      stop.present? && CAUSAS_PROBLEMA.include?(causa)
    end

    ultima_queda = quedas.first

    sessoes_por_dia = sessoes_validas
      .group_by { |start, _, _, _, _| start.to_date }
      .transform_keys { |date| date.strftime('%d/%m') }
      .transform_values(&:count)

    sessoes_com_dados = sessoes_validas.select do |_, stop, _, inp, out|
      stop.present? && inp.present? && out.present?
    end

    download_total = sessoes_com_dados.sum { |_, _, _, _, out| out }
    upload_total   = sessoes_com_dados.sum { |_, _, _, inp, _| inp }

    transferencia_por_dia = sessoes_com_dados
      .group_by { |start, _, _, _, _| start.to_date }
      .transform_keys { |date| date.strftime('%d/%m') }
      .transform_values do |grupo|
        {
          download_mb: (grupo.sum { |_, _, _, _, out| out } / 1_048_576.0).round(1),
          upload_mb: (grupo.sum { |_, _, _, inp, _| inp } / 1_048_576.0).round(1)
        }
      end

    {
      sessao_atual_inicio: sessao_atual ? sessao_atual[0].strftime('%d/%m/%Y %H:%M') : nil,
      sessoes_7_dias: sessoes_validas.count,
      quedas_7_dias: quedas.count,
      padrao_instavel: quedas.count > 3,
      ultima_queda: ultima_queda ? ultima_queda[0].strftime('%d/%m/%Y %H:%M') : nil,
      ultima_causa: ultima_queda ? ultima_queda[2] : nil,
      sessoes_por_dia: sessoes_por_dia,
      transferencia_7_dias: {
        download_mb: (download_total / 1_048_576.0).round(1),
        upload_mb: (upload_total / 1_048_576.0).round(1),
        por_dia: transferencia_por_dia
      }
    }
  end

  def sessoes_vazias
    {
      sessao_atual_inicio: nil,
      sessoes_7_dias: 0,
      quedas_7_dias: 0,
      padrao_instavel: false,
      ultima_queda: nil,
      ultima_causa: nil,
      sessoes_por_dia: {},
      transferencia_7_dias: { download_mb: 0.0, upload_mb: 0.0, por_dia: {} }
    }
  end
end

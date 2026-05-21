# frozen_string_literal: true

module ConexoesHelper
  include FibraRedesHelper

  def conexoes_params(params)
    params.permit(
      :tab, :sem_autenticar, :suspensas, :ativas, :conectadas, :desconectadas,
      :sem_contrato, conexao_q: [:usuario_or_mac_or_pessoa_nome_cont]
    )
  end

  def parcelas_instalacao_display(contrato)
    return '' unless contrato.valor_instalacao.positive?
    return 'À Vista' if contrato.parcelas_instalacao.zero?

    contrato.parcelas_instalacao
  end

  def parcelas_vencimento(contrato)
    return '' unless contrato.parcelas_instalacao.positive?

    contrato.faturas.first(contrato.parcelas_instalacao).map { |f| I18n.l(f.vencimento) }.join(', ')
  end

  def conexao_map_markers(conexao) # rubocop:disable Metrics/AbcSize
    markers = []
    if conexao.latitude.present? && conexao.longitude.present?
      markers << {
        id: 'current',
        lat: conexao.latitude.to_f,
        lng: conexao.longitude.to_f,
        title: conexao.pessoa&.nome || 'Nova Conexão',
        color: '#007bff',
        draggable: true,
        popup: "#{conexao.pessoa&.nome || 'Nova Conexão'}<br>Lat: #{conexao.latitude}<br>Lng: #{conexao.longitude}<br><em>Arraste para ajustar</em>"
      }
    elsif conexao.ponto.present?
      conexao.ponto.conexoes.georeferencidas.limit(20).each do |nearby|
        markers << {
          id: nearby.id,
          lat: nearby.latitude.to_f,
          lng: nearby.longitude.to_f,
          title: nearby.pessoa.nome,
          color: '#6c757d',
          draggable: false,
          popup: "#{nearby.pessoa.nome}<br>IP: #{nearby.ip}"
        }
      end
    end
    markers
  end

  def conexao_map_center(conexao) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
    {
      lat: conexao.latitude&.to_f  || conexao.ponto&.latitude&.to_f  || -8.3594,
      lng: conexao.longitude&.to_f || conexao.ponto&.longitude&.to_f || -36.9608,
      zoom: conexao.latitude.present? ? 18 : 15
    }
  end
end

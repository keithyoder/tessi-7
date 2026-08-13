# frozen_string_literal: true

class Os::RoteirizacaoService # rubocop:disable Style/ClassAndModuleChildren
  RAIO_KM = 5.0
  ORDEM_SLA = %i[atrasado em_risco no_prazo sem_sla].freeze

  def call
    pontos = coletar_pontos

    grupos = agrupar_por_proximidade(pontos)
      .map { |grupo| { os_list: grupo, sla_status: pior_sla(grupo), nome: nomear_grupo(grupo) } }
      .sort_by { |g| [ORDEM_SLA.index(g[:sla_status]), -g[:os_list].size] }

    { grupos: grupos, sem_coordenadas: sem_coordenadas }
  end

  private

  def coletar_pontos
    @sem_coordenadas = []
    os_list = Os.abertas.includes(
      :classificacao,
      pessoa: [
        { logradouro: { bairro: { cidade: :estado } } },
        { bairro: { cidade: :estado } },
        :cidade
      ],
      conexao: [
        { logradouro: { bairro: { cidade: :estado } } },
        { pessoa: { logradouro: { bairro: { cidade: :estado } } } }
      ]
    ).to_a

    carregar_medias_por_logradouro(os_list)

    os_list.filter_map do |os|
      lat, lng, fonte = coordenadas_para(os)

      if lat.nil?
        @sem_coordenadas << os
        next
      end

      { os: os, lat: lat, lng: lng, fonte: fonte }
    end
  end

  def sem_coordenadas
    @sem_coordenadas ||= []
  end

  def carregar_medias_por_logradouro(os_list)
    logradouro_ids = os_list.filter_map do |os|
      os.pessoa.logradouro_id unless coordenadas_proprias?(os.pessoa)
    end.uniq

    @media_por_logradouro = {}
    return if logradouro_ids.empty?

    @media_por_logradouro = Conexao.georeferenciadas
      .joins(:pessoa)
      .where('COALESCE(conexoes.logradouro_id, pessoas.logradouro_id) IN (?)', logradouro_ids)
      .group('COALESCE(conexoes.logradouro_id, pessoas.logradouro_id)')
      .pluck(
        Arel.sql('COALESCE(conexoes.logradouro_id, pessoas.logradouro_id)'),
        Arel.sql('AVG(conexoes.latitude)'),
        Arel.sql('AVG(conexoes.longitude)'),
        Arel.sql('COUNT(*)')
      )
      .each_with_object({}) { |(id, lat, lng, count), h| h[id] = [lat, lng, count] }
  end

  def coordenadas_proprias?(pessoa)
    pessoa.latitude.present? && pessoa.longitude.present?
  end

  def coordenadas_para(os)
    pessoa = os.pessoa
    return [pessoa.latitude, pessoa.longitude, 'pessoa'] if coordenadas_proprias?(pessoa)

    media = @media_por_logradouro[pessoa.logradouro_id]
    return [nil, nil, nil] if media.nil?

    lat, lng, count = media
    [lat, lng, "aprox. média de #{count} conexão#{'ões' if count > 1} no logradouro"]
  end

  def agrupar_por_proximidade(pontos)
    n = pontos.size
    return [] if n.zero?

    distancias = Array.new(n) { Array.new(n, 0.0) }
    (0...n).each do |i|
      ((i + 1)...n).each do |j|
        d = haversine(pontos[i][:lat], pontos[i][:lng], pontos[j][:lat], pontos[j][:lng])
        distancias[i][j] = d
        distancias[j][i] = d
      end
    end

    clusters = {}
    n.times { |i| clusters[i] = [i] }

    cluster_dist = {}
    clusters.keys.combination(2).each do |a, b|
      cluster_dist[[a, b]] = clusters[a].product(clusters[b]).map { |i, j| distancias[i][j] }.max
    end

    next_id = n

    loop do
      candidatos = cluster_dist.select { |_, d| d <= RAIO_KM }
      break if candidatos.empty?

      (a, b), = candidatos.min_by { |_, d| d }

      novo_id = next_id
      next_id += 1
      clusters[novo_id] = clusters[a] + clusters[b]

      cluster_dist.reject! { |(x, y), _| [x, y].include?(a) || [x, y].include?(b) }
      clusters.delete(a)
      clusters.delete(b)

      clusters.each_key do |outro_id|
        next if outro_id == novo_id

        d = clusters[novo_id].product(clusters[outro_id]).map { |i, j| distancias[i][j] }.max
        cluster_dist[[novo_id, outro_id].sort] = d
      end
    end

    clusters.values.map { |indices| indices.map { |i| pontos[i][:os] } }
  end

  def distancia_maxima(c1, c2, pontos)
    c1.flat_map do |i|
      c2.map do |j|
        haversine(pontos[i][:lat], pontos[i][:lng], pontos[j][:lat], pontos[j][:lng])
      end
    end.max
  end

  def nomear_grupo(grupo)
    municipio = grupo.map { |os| os.pessoa.cidade&.nome }.compact.first || 'Município desconhecido'

    logradouros = grupo.filter_map { |os| os.pessoa.logradouro&.nome }
    principais = logradouros.tally.sort_by { |_, count| -count }.first(2).map(&:first)

    "#{municipio} - #{principais.join('/')}"
  end

  def pior_sla(grupo)
    grupo.map(&:sla_status).min_by { |status| ORDEM_SLA.index(status) }
  end

  def haversine(lat1, lng1, lat2, lng2)
    r = 6371
    dlat = Math::PI * (lat2 - lat1) / 180
    dlng = Math::PI * (lng2 - lng1) / 180
    a = (Math.sin(dlat / 2)**2) +
        (Math.cos(Math::PI * lat1 / 180) * Math.cos(Math::PI * lat2 / 180) * (Math.sin(dlng / 2)**2))
    r * 2 * Math.asin(Math.sqrt(a))
  end
end

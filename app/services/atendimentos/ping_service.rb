# frozen_string_literal: true

module Atendimentos
  class PingService
    PACOTES      = 10
    INTERVALO    = 0.2
    TIMEOUT      = 2
    PORTA_ACESSO = 8087

    INACESSIVEL = {
      acessivel: false,
      pacotes_enviados: PACOTES,
      pacotes_recebidos: 0,
      perda_percentual: 100.0,
      latencia_min_ms: nil,
      latencia_avg_ms: nil,
      latencia_max_ms: nil,
      jitter_ms: nil,
      tcp_porta: nil,
      tcp_acessivel: nil,
      erro: 'Host inacessível'
    }.freeze

    def self.call(ip)
      new(ip).call
    end

    def initialize(ip)
      @ip = ip.to_s.strip
    end

    def call
      return { acessivel: false, erro: 'IP não configurado' } if @ip.blank?

      icmp   = icmp_ping
      tcp    = tcp_check
      icmp.merge(tcp)
    rescue StandardError => e
      Rails.logger.error("[PingService] Erro ao pingar #{@ip}: #{e.message}")
      { acessivel: false, erro: e.message }
    end

    private

    def icmp_ping
      saida = executar_ping
      parsear_resultado(saida)
    end

    def tcp_check
      inicio = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      Socket.tcp(@ip, PORTA_ACESSO, connect_timeout: TIMEOUT) {}
      latencia = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - inicio) * 1000).round(2)
      { tcp_porta: PORTA_ACESSO, tcp_acessivel: true, tcp_latencia_ms: latencia }
    rescue Errno::ECONNREFUSED
      # Port closed but host is UP — router is reachable, just port not open
      { tcp_porta: PORTA_ACESSO, tcp_acessivel: false, tcp_erro: 'Porta fechada (router online)' }
    rescue Errno::ETIMEDOUT, Errno::EHOSTUNREACH, SocketError
      { tcp_porta: PORTA_ACESSO, tcp_acessivel: false, tcp_erro: 'Timeout' }
    end

    def executar_ping
      `#{comando_ping} 2>&1`
    end

    def comando_ping
      if macos?
        "ping -c #{PACOTES} -i #{INTERVALO} -W #{TIMEOUT * 1000} #{@ip}"
      else
        "ping -c #{PACOTES} -i #{INTERVALO} -W #{TIMEOUT} -w #{((PACOTES * INTERVALO) + (TIMEOUT * 2)).ceil} #{@ip}"
      end
    end

    def macos?
      RUBY_PLATFORM.include?('darwin')
    end

    def parsear_resultado(saida)
      perda = parsear_perda(saida)

      if perda >= 100.0 || saida.include?('Communication prohibited') || saida.include?('Network unreachable')
        return INACESSIVEL.dup.tap { |h| h[:erro] = diagnosticar_erro(saida) }
      end

      estatisticas = parsear_estatisticas(saida)
      return INACESSIVEL.merge(erro: 'Resposta insuficiente') if estatisticas.nil?

      min, avg, max, jitter = estatisticas
      recebidos = (PACOTES * (1 - (perda / 100.0))).round

      {
        acessivel: true,
        pacotes_enviados: PACOTES,
        pacotes_recebidos: recebidos,
        perda_percentual: perda,
        latencia_min_ms: min.round(2),
        latencia_avg_ms: avg.round(2),
        latencia_max_ms: max.round(2),
        jitter_ms: jitter.round(2),
        erro: perda > 0 ? "#{perda}% de perda de pacotes" : nil
      }
    end

    def parsear_estatisticas(saida)
      match = saida.match(%r{(?:rtt|round-trip)\s+min/avg/max/(?:mdev|stddev)\s+=\s+(\d+\.\d+)/(\d+\.\d+)/(\d+\.\d+)/(\d+\.\d+)})
      return nil unless match

      match.captures.map(&:to_f)
    end

    def parsear_perda(saida)
      match = saida.match(/(\d+(?:\.\d+)?)%\s+packet loss/)
      match ? match[1].to_f : 100.0
    end

    def diagnosticar_erro(saida)
      return 'Filtro ICMP ativo (Communication prohibited)' if saida.include?('Communication prohibited')
      return 'Rede inacessível'                             if saida.include?('Network unreachable')
      return 'Host inacessível'                             if saida.include?('Host unreachable')
      return 'Timeout'                                      if saida.include?('Request timeout')

      'Sem resposta'
    end
  end
end

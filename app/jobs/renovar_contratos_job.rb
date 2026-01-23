# frozen_string_literal: true

# Job responsável por renovar contratos em lote.
#
# Este job delega toda a lógica de negócio para Contratos::RenovacaoEmLoteService
# e é responsável apenas por:
# - Agendar a execução
# - Apresentar o resultado ao usuário
#
class RenovarContratosJob < ApplicationJob
  queue_as :default

  def perform(pagamento_perfil_id: 1, meses_por_fatura: 1)
    resultado = Contratos::RenovacaoEmLoteService.new(
      pagamento_perfil_id: pagamento_perfil_id,
      meses_por_fatura: meses_por_fatura
    ).call

    imprimir_relatorio(resultado)
  end

  private

  # rubocop:disable Rails/Output, Metrics/AbcSize
  def imprimir_relatorio(resultado)
    puts "\n#{'=' * 60}"
    puts 'RELATÓRIO DE RENOVAÇÃO DE CONTRATOS'
    puts '=' * 60

    if resultado.sucesso.any?
      puts "\n✓ Contratos renovados (#{resultado.total_renovados}):"
      resultado.sucesso.each { |nome| puts "  - #{nome}" }
    end

    if resultado.ignorados.any?
      puts "\n⊘ Contratos ignorados (#{resultado.total_ignorados}):"
      resultado.ignorados.each { |nome| puts "  - #{nome}" }
    end

    if resultado.erros.any?
      puts "\n✗ Erros (#{resultado.total_erros}):"
      resultado.erros.each { |nome, erro| puts "  - #{nome}: #{erro}" }
    end

    puts '=' * 60
  end
  # rubocop:enable Rails/Output, Metrics/AbcSize
end

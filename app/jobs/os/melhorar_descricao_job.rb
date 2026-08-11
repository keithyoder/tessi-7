# frozen_string_literal: true

class Os::MelhorarDescricaoJob < ApplicationJob # rubocop:disable Style/ClassAndModuleChildren
  queue_as :default

  def perform(os_id)
    os = Os.find_by(id: os_id)
    return if os.nil? || os.descricao.blank?

    texto_melhorado = Os::MelhorarTextoService.new(
      texto: os.descricao,
      tipo: os.tipo,
      classificacao: os.classificacao&.nome
    ).call

    os.update_column(:descricao, texto_melhorado) # rubocop:disable Rails/SkipsModelValidations
  rescue Os::MelhorarTextoService::ErroApi => e
    Rails.logger.error("Erro ao melhorar descrição da OS #{os_id}: #{e.message}")
  end
end

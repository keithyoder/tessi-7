class Device < ApplicationRecord
  belongs_to :deviceable, polymorphic: true
  belongs_to :equipamento, optional: true

  validates :deviceable_type, inclusion: { in: %w[Ponto Conexao] }
  validates :mac, uniqueness: true, allow_nil: true

  def ip
    deviceable.ip.to_s
  end

  def name
    case deviceable
    when Ponto then deviceable.nome
    when Conexao then "#{deviceable.pessoa.nome} #{deviceable.observacao.to_s.first(10)}".strip
    end
  end

  def servidor_nome
    case deviceable
    when Ponto then deviceable.servidor.nome
    when Conexao then deviceable.ponto.servidor.nome
    end
  end

  def ap?
    deviceable_type == 'Ponto'
  end

  def effective_user
    usuario.presence || default_user
  end

  def effective_password
    senha.presence || default_password
  end

  private

  def default_user = 'admin'
  def default_password = nil
end

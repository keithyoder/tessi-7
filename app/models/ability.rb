# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return unless user.present?

    general_permissions(user) if user.role?

    if user.admin?
      admin_permissions
    elsif user.tecnico_n1?
      tecnico_n1_permissions
    elsif user.tecnico_n2?
      tecnico_n2_permissions
    elsif user.financeiro_n1?
      financeiro_n1_permissions
    elsif user.financeiro_n2?
      financeiro_n2_permissions
    end
  end

  private

  # Common permissions for all users with a role
  def general_permissions(user)
    can :read, :all
    can :suspenso, Conexao
    can %i[boletos renovar], Contrato
    can %i[update liquidacao boleto], Fatura

    # Only allow encerrar on Atendimento assigned to the user and not closed
    can :encerrar, Atendimento, responsavel_id: user.id, fechamento: nil

    can :mapa, Servidor
    can %i[create update], [Bairro, Logradouro, Conexao, Pessoa, Os, Atendimento, AtendimentoDetalhe]
    can :impressao, Os
    can :create, Excecao
    can :update, Os, fechamento: nil
  end

  # Admin permissions
  def admin_permissions
    can :manage, :all
    cannot %i[destroy create], Estado
    can :encerrar, Atendimento, fechamento: nil
  end

  # Level 1 technician
  def tecnico_n1_permissions
    can :update, FibraCaixa
    can %i[create update], Conexao
  end

  # Level 2 technician
  def tecnico_n2_permissions
    can :update, [Cidade, Ponto, Servidor]
    can %i[create update], [FibraRede, FibraCaixa, IpRede, Conexao, Equipamento]
    can :destroy, Conexao
    can %i[backup backups], Servidor
  end

  # Level 1 financial
  def financeiro_n1_permissions
    can %i[update liquidacao], Fatura
    can :termo, Contrato
  end

  # Level 2 financial
  def financeiro_n2_permissions
    can :update, Cidade
    can :destroy, Conexao
    can %i[update liquidacao estornar cancelar gerar_nf], Fatura
    can %i[create update], [Retorno, Contrato]
    can %i[destroy termo pendencias autentique trocado], Contrato
    can :remessa, PagamentoPerfil
  end
end

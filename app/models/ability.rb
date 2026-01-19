# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    return if user.blank?

    todos(user) if user.role?

    if user.admin?
      admin
    elsif user.tecnico_n1?
      tecnico_n1
    elsif user.tecnico_n2?
      tecnico_n2
    elsif user.financeiro_n1?
      financeiro_n1
    elsif user.financeiro_n2?
      financeiro_n2
    end
  end

  private

  def todos(user)
    can :read, :all
    can :suspenso, Conexao
    can %i[boletos renovar], Contrato
    can %i[udate liquidacao boleto], Fatura

    # Only allow encerrar on Atendimento assigned to the user and not closed
    can :encerrar, Atendimento, responsavel_id: user.id, fechamento: nil

    can :mapa, Servidor
    can %i[create update], [Bairro, Logradouro, Conexao, Pessoa, Os, AtendimentoDetalhe]
    can :impressao, Os

    # Avoid loading all closed OS into memory: use SQL-friendly condition
    cannot :update, Os, ["fechamento IS NOT NULL"]

    can :create, [Excecao]
  end

  def admin
    can :manage, :all

    # Only block destroying Estado or closing already closed Atendimento
    cannot :destroy, Estado
    cannot :encerrar, Atendimento, ["fechamento IS NOT NULL"]
  end

  def tecnico_n1
    can :update, [FibraCaixa]
    can %i[create update], Conexao
  end

  def tecnico_n2
    can :update, [Cidade, Ponto, Servidor]
    can %i[create update], [FibraRede, FibraCaixa, IpRede, Conexao, Equipamento]
    can :destroy, Conexao
    can %i[backup backups], Servidor
  end

  def financeiro_n1
    can %i[update liquidacao], Fatura
    can %i[termo], [Contrato]
  end

  def financeiro_n2
    can :update, Cidade
    can :destroy, Conexao
    can %i[update liquidacao estornar cancelar gerar_nf], Fatura
    can %i[create update autentique], [Retorno, Contrato]
    can %i[destroy termo pendencias], Contrato
    can :remessa, PagamentoPerfil
  end
end

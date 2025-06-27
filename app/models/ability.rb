# frozen_string_literal: true

class Ability
  include CanCan::Ability

  def initialize(user)
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/CanCanCommunity/cancancan/wiki/Defining-Abilities
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
    can :encerrar, Atendimento.por_responsavel(user).abertos
    can :mapa, Servidor
    can %i[create update], [Bairro, Logradouro, Conexao, Pessoa, Os, Atendimento, AtendimentoDetalhe]
    can :impressao, Os
    cannot :update, Os.fechadas
    can :create, [Excecao]
  end

  def admin
    can :manage, :all
    cannot :destroy, Estado
    cannot :encerrar, Atendimento.fechados
  end

  def tecnico_n1
    can [:update], [FibraCaixa]
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

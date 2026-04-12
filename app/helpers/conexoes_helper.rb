# frozen_string_literal: true

# == Schema Information
#
# Table name: conexoes
#
#  id             :bigint           not null, primary key
#  auto_bloqueio  :boolean
#  bloqueado      :boolean
#  complemento    :string
#  inadimplente   :boolean          default(FALSE), not null
#  ip             :inet
#  ipv6           :inet
#  latitude       :decimal(10, 6)
#  longitude      :decimal(10, 6)
#  mac            :string
#  numero         :string
#  observacao     :string
#  pool           :cidr
#  porta          :integer
#  senha          :string
#  tipo           :integer
#  usuario        :string
#  velocidade     :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  caixa_id       :bigint
#  contrato_id    :bigint
#  equipamento_id :bigint
#  logradouro_id  :bigint
#  pessoa_id      :bigint
#  plano_id       :bigint
#  ponto_id       :bigint
#
# Indexes
#
#  index_conexoes_on_caixa_id        (caixa_id)
#  index_conexoes_on_contrato_id     (contrato_id)
#  index_conexoes_on_equipamento_id  (equipamento_id)
#  index_conexoes_on_logradouro_id   (logradouro_id)
#  index_conexoes_on_pessoa_id       (pessoa_id)
#  index_conexoes_on_plano_id        (plano_id)
#  index_conexoes_on_ponto_id        (ponto_id)
#
# Foreign Keys
#
#  fk_rails_...  (logradouro_id => logradouros.id)
#  fk_rails_...  (pessoa_id => pessoas.id)
#  fk_rails_...  (plano_id => planos.id)
#  fk_rails_...  (ponto_id => pontos.id)
#
module ConexoesHelper
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
end

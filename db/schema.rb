# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_05_31_134217) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "atendimento_detalhes", force: :cascade do |t|
    t.bigint "atendimento_id"
    t.integer "tipo"
    t.bigint "atendente_id"
    t.text "descricao"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["atendente_id"], name: "index_atendimento_detalhes_on_atendente_id"
    t.index ["atendimento_id"], name: "index_atendimento_detalhes_on_atendimento_id"
  end

  create_table "atendimentos", force: :cascade do |t|
    t.bigint "pessoa_id"
    t.bigint "classificacao_id"
    t.bigint "responsavel_id"
    t.datetime "fechamento"
    t.bigint "contrato_id"
    t.bigint "conexao_id"
    t.bigint "fatura_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["classificacao_id"], name: "index_atendimentos_on_classificacao_id"
    t.index ["conexao_id"], name: "index_atendimentos_on_conexao_id"
    t.index ["contrato_id"], name: "index_atendimentos_on_contrato_id"
    t.index ["fatura_id"], name: "index_atendimentos_on_fatura_id"
    t.index ["pessoa_id"], name: "index_atendimentos_on_pessoa_id"
    t.index ["responsavel_id"], name: "index_atendimentos_on_responsavel_id"
  end

  create_table "bairros", force: :cascade do |t|
    t.string "nome"
    t.bigint "cidade_id"
    t.decimal "latitude"
    t.decimal "longitude"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["cidade_id"], name: "index_bairros_on_cidade_id"
  end

  create_table "cidades", force: :cascade do |t|
    t.string "nome"
    t.bigint "estado_id"
    t.string "ibge"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estado_id", "nome"], name: "index_cidades_on_estado_id_and_nome", unique: true
    t.index ["estado_id"], name: "index_cidades_on_estado_id"
  end

  create_table "classificacoes", force: :cascade do |t|
    t.integer "tipo"
    t.string "nome"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "conexao_enviar_atributos", force: :cascade do |t|
    t.bigint "conexao_id"
    t.string "atributo"
    t.string "op"
    t.string "valor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conexao_id", "atributo"], name: "index_conexao_enviar_atributos_on_conexao_id_and_atributo", unique: true
    t.index ["conexao_id"], name: "index_conexao_enviar_atributos_on_conexao_id"
  end

  create_table "conexao_verificar_atributos", force: :cascade do |t|
    t.bigint "conexao_id"
    t.string "atributo"
    t.string "op"
    t.string "valor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conexao_id", "atributo"], name: "index_conexao_verificar_atributos_on_conexao_id_and_atributo", unique: true
    t.index ["conexao_id"], name: "index_conexao_verificar_atributos_on_conexao_id"
  end

  create_table "conexoes", force: :cascade do |t|
    t.bigint "pessoa_id"
    t.bigint "plano_id"
    t.bigint "ponto_id"
    t.inet "ip"
    t.string "velocidade"
    t.boolean "bloqueado"
    t.boolean "auto_bloqueio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "observacao"
    t.string "usuario"
    t.string "senha"
    t.boolean "inadimplente", default: false, null: false
    t.bigint "contrato_id"
    t.string "mac"
    t.integer "tipo"
    t.bigint "caixa_id"
    t.integer "porta"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.bigint "equipamento_id"
    t.index ["caixa_id"], name: "index_conexoes_on_caixa_id"
    t.index ["contrato_id"], name: "index_conexoes_on_contrato_id"
    t.index ["equipamento_id"], name: "index_conexoes_on_equipamento_id"
    t.index ["pessoa_id"], name: "index_conexoes_on_pessoa_id"
    t.index ["plano_id"], name: "index_conexoes_on_plano_id"
    t.index ["ponto_id"], name: "index_conexoes_on_ponto_id"
  end

  create_table "contratos", force: :cascade do |t|
    t.bigint "pessoa_id", null: false
    t.bigint "plano_id", null: false
    t.integer "status"
    t.integer "dia_vencimento"
    t.date "adesao"
    t.decimal "valor_instalacao", precision: 8, scale: 2
    t.integer "numero_conexoes", default: 1
    t.date "cancelamento"
    t.boolean "emite_nf", default: true
    t.date "primeiro_vencimento"
    t.integer "prazo_meses", default: 12
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "pagamento_perfil_id"
    t.integer "parcelas_instalacao"
    t.index ["pagamento_perfil_id"], name: "index_contratos_on_pagamento_perfil_id"
    t.index ["pessoa_id"], name: "index_contratos_on_pessoa_id"
    t.index ["plano_id"], name: "index_contratos_on_plano_id"
  end

  create_table "equipamentos", force: :cascade do |t|
    t.string "fabricante"
    t.string "modelo"
    t.integer "tipo"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "estados", force: :cascade do |t|
    t.string "sigla"
    t.string "nome"
    t.integer "ibge"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nome"], name: "index_estados_on_nome", unique: true
  end

  create_table "excecoes", force: :cascade do |t|
    t.bigint "contrato_id"
    t.date "valido_ate"
    t.integer "tipo"
    t.string "usuario"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contrato_id"], name: "index_excecoes_on_contrato_id"
  end

  create_table "faturas", force: :cascade do |t|
    t.bigint "contrato_id"
    t.decimal "valor", null: false
    t.date "vencimento", null: false
    t.string "nossonumero", null: false
    t.integer "parcela", null: false
    t.string "arquivo_remessa"
    t.date "data_remessa"
    t.date "data_cancelamento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.date "liquidacao"
    t.decimal "valor_liquidacao", precision: 8, scale: 2
    t.date "vencimento_original"
    t.decimal "valor_original", precision: 8, scale: 2
    t.integer "meio_liquidacao"
    t.date "periodo_inicio"
    t.date "periodo_fim"
    t.bigint "pagamento_perfil_id"
    t.decimal "juros_recebidos"
    t.decimal "desconto_concedido"
    t.integer "banco"
    t.integer "agencia"
    t.bigint "retorno_id"
    t.bigint "registro_id"
    t.bigint "baixa_id"
    t.datetime "cancelamento"
    t.string "pix"
    t.integer "id_externo"
    t.string "link"
    t.string "codigo_de_barras"
    t.index ["baixa_id"], name: "index_faturas_on_baixa_id"
    t.index ["contrato_id"], name: "index_faturas_on_contrato_id"
    t.index ["liquidacao"], name: "index_faturas_on_liquidacao"
    t.index ["meio_liquidacao", "liquidacao"], name: "index_faturas_on_meio_liquidacao_and_liquidacao"
    t.index ["pagamento_perfil_id", "nossonumero"], name: "index_faturas_on_pagamento_perfil_id_and_nossonumero"
    t.index ["pagamento_perfil_id"], name: "index_faturas_on_pagamento_perfil_id"
    t.index ["registro_id"], name: "index_faturas_on_registro_id"
    t.index ["retorno_id"], name: "index_faturas_on_retorno_id"
    t.index ["vencimento"], name: "index_faturas_on_vencimento"
  end

  create_table "fibra_caixas", force: :cascade do |t|
    t.string "nome"
    t.bigint "fibra_rede_id"
    t.integer "capacidade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "logradouro_id"
    t.string "poste"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.integer "fibra_cor"
    t.index ["fibra_rede_id"], name: "index_fibra_caixas_on_fibra_rede_id"
    t.index ["logradouro_id"], name: "index_fibra_caixas_on_logradouro_id"
  end

  create_table "fibra_redes", force: :cascade do |t|
    t.string "nome"
    t.bigint "ponto_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "fibra_cor"
    t.index ["ponto_id"], name: "index_fibra_redes_on_ponto_id"
  end

  create_table "ip_redes", force: :cascade do |t|
    t.inet "rede"
    t.bigint "ponto_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["ponto_id"], name: "index_ip_redes_on_ponto_id"
  end

  create_table "logradouros", force: :cascade do |t|
    t.string "nome"
    t.bigint "bairro_id"
    t.string "cep"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["bairro_id"], name: "index_logradouros_on_bairro_id"
  end

  create_table "nf21_itens", force: :cascade do |t|
    t.bigint "nf21_id"
    t.text "item"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["nf21_id"], name: "index_nf21_itens_on_nf21_id"
  end

  create_table "nf21s", force: :cascade do |t|
    t.bigint "fatura_id"
    t.date "emissao"
    t.integer "numero"
    t.decimal "valor", precision: 8, scale: 2
    t.text "cadastro"
    t.text "mestre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["fatura_id"], name: "index_nf21s_on_fatura_id"
  end

  create_table "os", force: :cascade do |t|
    t.integer "tipo"
    t.bigint "classificacao_id"
    t.bigint "pessoa_id"
    t.bigint "conexao_id"
    t.bigint "aberto_por_id"
    t.bigint "responsavel_id"
    t.bigint "tecnico_1_id"
    t.bigint "tecnico_2_id"
    t.datetime "fechamento"
    t.text "descricao"
    t.text "encerramento"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["aberto_por_id"], name: "index_os_on_aberto_por_id"
    t.index ["classificacao_id"], name: "index_os_on_classificacao_id"
    t.index ["conexao_id"], name: "index_os_on_conexao_id"
    t.index ["pessoa_id"], name: "index_os_on_pessoa_id"
    t.index ["responsavel_id"], name: "index_os_on_responsavel_id"
    t.index ["tecnico_1_id"], name: "index_os_on_tecnico_1_id"
    t.index ["tecnico_2_id"], name: "index_os_on_tecnico_2_id"
  end

  create_table "pagamento_perfis", force: :cascade do |t|
    t.string "nome"
    t.integer "tipo"
    t.integer "cedente"
    t.integer "agencia"
    t.integer "conta"
    t.string "carteira"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "banco"
    t.string "variacao"
    t.integer "sequencia"
    t.string "client_id"
    t.string "client_secret"
  end

  create_table "pessoas", force: :cascade do |t|
    t.string "nome"
    t.integer "tipo"
    t.string "cpf"
    t.string "cnpj"
    t.string "rg"
    t.string "ie"
    t.date "nascimento"
    t.bigint "logradouro_id"
    t.string "numero"
    t.string "complemento"
    t.string "nomemae"
    t.string "email"
    t.string "telefone1"
    t.string "telefone2"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.index ["logradouro_id"], name: "index_pessoas_on_logradouro_id"
    t.index ["nome"], name: "index_pessoas_on_nome"
  end

  create_table "plano_enviar_atributos", force: :cascade do |t|
    t.bigint "plano_id"
    t.string "atributo"
    t.string "op"
    t.string "valor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plano_id", "atributo"], name: "index_plano_enviar_atributos_on_plano_id_and_atributo", unique: true
    t.index ["plano_id"], name: "index_plano_enviar_atributos_on_plano_id"
  end

  create_table "plano_verificar_atributos", force: :cascade do |t|
    t.bigint "plano_id"
    t.string "atributo"
    t.string "op"
    t.string "valor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["plano_id", "atributo"], name: "index_plano_verificar_atributos_on_plano_id_and_atributo", unique: true
    t.index ["plano_id"], name: "index_plano_verificar_atributos_on_plano_id"
  end

  create_table "planos", force: :cascade do |t|
    t.string "nome"
    t.decimal "mensalidade", precision: 8, scale: 2
    t.integer "upload"
    t.integer "download"
    t.boolean "burst"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "desconto", precision: 8, scale: 2
    t.index ["nome"], name: "index_planos_on_nome", unique: true
  end

  create_table "pontos", force: :cascade do |t|
    t.string "nome"
    t.integer "sistema"
    t.integer "tecnologia"
    t.bigint "servidor_id"
    t.inet "ip"
    t.string "usuario"
    t.string "senha"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ssid"
    t.string "frequencia"
    t.integer "canal_tamanho"
    t.string "equipamento"
    t.index ["servidor_id"], name: "index_pontos_on_servidor_id"
  end

  create_table "radacct", primary_key: "radacctid", force: :cascade do |t|
    t.text "acctsessionid", null: false
    t.text "acctuniqueid", null: false
    t.text "username"
    t.text "groupname"
    t.text "realm"
    t.inet "nasipaddress", null: false
    t.text "nasportid"
    t.text "nasporttype"
    t.datetime "acctstarttime"
    t.datetime "acctupdatetime"
    t.datetime "acctstoptime"
    t.bigint "acctinterval"
    t.bigint "acctsessiontime"
    t.text "acctauthentic"
    t.text "connectinfo_start"
    t.text "connectinfo_stop"
    t.bigint "acctinputoctets"
    t.bigint "acctoutputoctets"
    t.text "calledstationid"
    t.text "callingstationid"
    t.text "acctterminatecause"
    t.text "servicetype"
    t.text "framedprotocol"
    t.inet "framedipaddress"
    t.bigint "pessoa_id"
    t.index ["acctstarttime", "username"], name: "radacct_start_user_idx"
    t.index ["acctuniqueid"], name: "radacct_acctuniqueid_key", unique: true
    t.index ["acctuniqueid"], name: "radacct_active_session_idx", where: "(acctstoptime IS NULL)"
    t.index ["nasipaddress", "acctstarttime"], name: "radacct_bulk_close", where: "(acctstoptime IS NULL)"
  end

  create_table "radpostauth", force: :cascade do |t|
    t.text "username", null: false
    t.text "pass"
    t.text "reply"
    t.text "calledstationid"
    t.text "callingstationid"
    t.datetime "authdate", default: -> { "now()" }, null: false
    t.index ["username", "authdate"], name: "radpostauth_username_authdate_idx"
  end

  create_table "retornos", force: :cascade do |t|
    t.bigint "pagamento_perfil_id"
    t.date "data"
    t.integer "sequencia"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pagamento_perfil_id"], name: "index_retornos_on_pagamento_perfil_id"
  end

  create_table "servidores", force: :cascade do |t|
    t.string "nome"
    t.string "usuario"
    t.string "senha"
    t.integer "api_porta"
    t.integer "ssh_porta"
    t.integer "snmp_porta"
    t.string "snmp_comunidade"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.inet "ip"
    t.boolean "ativo"
    t.boolean "up"
    t.string "radius_secret"
    t.integer "radius_porta"
    t.string "versao"
    t.string "equipamento"
  end

  create_table "settings", force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["var"], name: "index_settings_on_var", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "role"
    t.string "primeiro_nome"
    t.string "nome_completo"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "webhook_eventos", force: :cascade do |t|
    t.bigint "webhook_id"
    t.datetime "processed_at"
    t.jsonb "headers"
    t.jsonb "body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["webhook_id"], name: "index_webhook_eventos_on_webhook_id"
  end

  create_table "webhooks", force: :cascade do |t|
    t.integer "tipo"
    t.string "token"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "atendimento_detalhes", "atendimentos"
  add_foreign_key "atendimento_detalhes", "users", column: "atendente_id"
  add_foreign_key "atendimentos", "classificacoes"
  add_foreign_key "atendimentos", "conexoes", on_delete: :nullify
  add_foreign_key "atendimentos", "contratos"
  add_foreign_key "atendimentos", "faturas"
  add_foreign_key "atendimentos", "pessoas"
  add_foreign_key "atendimentos", "users", column: "responsavel_id"
  add_foreign_key "bairros", "cidades"
  add_foreign_key "cidades", "estados"
  add_foreign_key "conexao_enviar_atributos", "conexoes", on_delete: :cascade
  add_foreign_key "conexao_verificar_atributos", "conexoes", on_delete: :cascade
  add_foreign_key "conexoes", "pessoas"
  add_foreign_key "conexoes", "planos"
  add_foreign_key "conexoes", "pontos"
  add_foreign_key "contratos", "pagamento_perfis"
  add_foreign_key "contratos", "pessoas"
  add_foreign_key "contratos", "planos"
  add_foreign_key "excecoes", "contratos"
  add_foreign_key "faturas", "contratos"
  add_foreign_key "faturas", "pagamento_perfis"
  add_foreign_key "faturas", "retornos", column: "baixa_id"
  add_foreign_key "faturas", "retornos", column: "registro_id"
  add_foreign_key "fibra_caixas", "fibra_redes"
  add_foreign_key "fibra_redes", "pontos"
  add_foreign_key "logradouros", "bairros"
  add_foreign_key "os", "classificacoes"
  add_foreign_key "os", "conexoes"
  add_foreign_key "os", "pessoas"
  add_foreign_key "os", "users", column: "aberto_por_id"
  add_foreign_key "os", "users", column: "responsavel_id"
  add_foreign_key "os", "users", column: "tecnico_1_id"
  add_foreign_key "os", "users", column: "tecnico_2_id"
  add_foreign_key "pessoas", "logradouros"
  add_foreign_key "plano_enviar_atributos", "planos", on_delete: :cascade
  add_foreign_key "plano_verificar_atributos", "planos", on_delete: :cascade
  add_foreign_key "pontos", "servidores"
  add_foreign_key "radacct", "pessoas", name: "fk_pessoa_id"
  add_foreign_key "webhook_eventos", "webhooks"
end

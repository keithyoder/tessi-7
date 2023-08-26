# frozen_string_literal: true

require 'cobranca/retorno_240'
require 'cobranca/retorno_400'
require 'cobranca/bb_400'

class Retorno < ApplicationRecord
  belongs_to :pagamento_perfil
  has_many :faturas, dependent: :restrict_with_exception
  has_many :registros,
           class_name: :Fatura,
           foreign_key: :registro_id,
           dependent: :restrict_with_exception,
           inverse_of: :registro
  has_many :baixas,
           class_name: :Fatura,
           foreign_key: :baixa_id,
           dependent: :restrict_with_exception,
           inverse_of: :baixa
  has_one_attached :arquivo

  ARQUIVO_COMPATIVEL = 'Arquivo não é compatível com o convênio selecionado'

  def verificar_header
    case pagamento_perfil.tipo
    when 'Boleto'
      data_file = File.open(
        ActiveStorage::Blob.service.send(:path_for, arquivo.key)
      )
      case pagamento_perfil.banco
      when 33
        header = Retorno240Header.load_line data_file.first
        raise StandardError.new, ARQUIVO_COMPATIVEL unless header.convenio.to_i == pagamento_perfil.cedente

        self.attributes = {
          sequencia: header.sequencia,
          data: cnab_to_date(header.data)
        }
        save
      when 1
        header = Retorno400Header.load_line data_file.first
        unless header.retorno.to_i == 2 && header.tipo.to_i == 1 && header.convenio.to_i == pagamento_perfil.cedente
          raise StandardError.new, ARQUIVO_COMPATIVEL
        end

        self.attributes = {
          sequencia: header.sequencia,
          data: cnab_to_date(header.data)
        }
        save
      end
    when 'Débito Automático'
    end
  end

  def processar
    verificar_header
    carregar_arquivo.each do |linha|
      next unless linha.data_ocorrencia.to_i.positive?

      fatura = Fatura.find_by(
        pagamento_perfil: pagamento_perfil,
        nossonumero: cnab_to_nosso_numero(linha.nosso_numero)
      )
      next if fatura.blank?
      # instrucao rejeitada
      next if linha.codigo_ocorrencia.to_i == 26

      case linha.codigo_ocorrencia.to_i
      when 6
        # titulo liquidado
        desconto = [0, cnab_to_float(linha.valor_recebido) - fatura.valor].min
        fatura.attributes = {
          liquidacao: cnab_to_date(linha.data_ocorrencia),
          juros_recebidos: cnab_to_float(linha.juros_mora),
          banco: linha.banco_recebedor,
          desconto_concedido: desconto,
          agencia: linha.agencia_recebedora_com_dv[0...-1],
          valor_liquidacao: cnab_to_float(linha.valor_recebido),
          meio_liquidacao: :RetornoBancario,
          retorno: self
        }
      when 2
        # titulo registrado
        fatura.attributes = {
          registro: self
        }
      when 9, 10
        # titulo baixado manualmente
        fatura.attributes = {
          baixa: self
        }
      end
      fatura.save
    end
    SuspensaoAutomaticaJob.perform_later if pode_supsender?
  end

  def carregar_arquivo
    case pagamento_perfil.banco
    when 33
      Brcobranca::Retorno::Cnab240::Santander.load_lines(
        ActiveStorage::Blob.service.send(:path_for, arquivo.key)
      )
    when 1
      Brcobranca::Retorno::Cnab400::BB.load_lines(
        ActiveStorage::Blob.service.send(:path_for, arquivo.key)
      )
    end
  end

  def cnab_to_float(valor)
    valor.to_f / 100
  end

  def cnab_to_currency(valor)
    number_to_currency(valor.to_f / 100)
  end

  def cnab_to_date(valor)
    if valor.length == 8
      Date.strptime(valor, '%d%m%Y')
    else
      Date.strptime(valor, '%d%m%y')
    end
  end

  def cnab_to_nosso_numero(valor)
    case pagamento_perfil.banco
    when 33
      # remove leading zeros and trailing digit
      valor.sub!(/^0+/, '')[0...-1]
    when 1
      valor[7..].sub(/^0+/, '')
    end
  end

  private

  def pode_suspender?
    Retorno.where(data: Time.zone.today - 1.day).count >= 2
  end
end

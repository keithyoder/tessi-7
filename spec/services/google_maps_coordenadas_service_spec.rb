# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GoogleMapsCoordenadasService do
  # `case response; when Net::HTTPRedirection` usa `===`, que para
  # Módulos/Classes checa a classe real do objeto no nível do Ruby/C —
  # isso NÃO passa por `is_a?` como método (então stubar `is_a?` num
  # double não funciona aqui). Por isso construímos instâncias reais
  # das classes de resposta, só sem chamar `initialize`.
  def resposta_redirecionamento(location)
    resposta = Net::HTTPFound.allocate
    resposta.instance_variable_set(:@header, { 'location' => [location] })
    resposta
  end

  def resposta_final
    resposta = Net::HTTPOK.allocate
    resposta.instance_variable_set(:@header, {})
    resposta
  end

  describe '.call' do
    context 'quando o texto não contém nenhum link do Google Maps' do
      it 'retorna nil' do
        resultado = described_class.call('Cliente sem referência informada')

        expect(resultado).to be_nil
      end
    end

    context 'quando o texto é nil' do
      it 'retorna nil sem levantar erro' do
        expect(described_class.call(nil)).to be_nil
      end
    end

    context 'quando o link já expandido contém o pino (!3d!4d)' do
      it 'extrai coordenadas do pino e reescreve o texto com o link canônico, sem chamada HTTP' do
        texto = 'Referência: https://www.google.com/maps/place/R.+Manoel+Borba,+48/' \
                '@-8.356038,-36.6805342,759m/data=!3m2!1e3!4b1!4m6!3m5!1s0x0:0x0' \
                '!8m2!3d-8.356038!4d-36.6805342'

        expect(Net::HTTP).not_to receive(:get_response)

        resultado = described_class.call(texto)

        expect(resultado).to eq(
          latitude: -8.356038,
          longitude: -36.6805342,
          link: 'https://www.google.com/maps?q=-8.356038,-36.6805342',
          texto: 'Referência: https://www.google.com/maps?q=-8.356038,-36.6805342'
        )
      end
    end

    context 'quando o link já expandido só tem o centro do viewport (@lat,lng)' do
      it 'extrai coordenadas do viewport e reescreve o texto' do
        texto = 'https://www.google.com/maps/@-8.05,-34.9,15z'

        resultado = described_class.call(texto)

        expect(resultado).to eq(
          latitude: -8.05,
          longitude: -34.9,
          link: 'https://www.google.com/maps?q=-8.05,-34.9',
          texto: 'https://www.google.com/maps?q=-8.05,-34.9'
        )
      end
    end

    context 'quando o link está no formato antigo maps.google.com/maps?q=' do
      it 'extrai coordenadas do parâmetro q e reescreve o texto' do
        texto = 'http://maps.google.com/maps?q=-8.05,-34.9'

        resultado = described_class.call(texto)

        expect(resultado).to eq(
          latitude: -8.05,
          longitude: -34.9,
          link: 'https://www.google.com/maps?q=-8.05,-34.9',
          texto: 'https://www.google.com/maps?q=-8.05,-34.9'
        )
      end
    end

    context 'quando o texto contém um link encurtado (maps.app.goo.gl)' do
      it 'segue os redirecionamentos e reescreve o texto com o link canônico' do
        texto = 'Referência: https://maps.app.goo.gl/Hht2RcC1XG6BvKSZ8'

        redirecionamento = resposta_redirecionamento(
          'https://www.google.com/maps/place/R.+Manoel+Borba,+48/' \
          '@-8.356038,-36.6805342,759m/data=!3d-8.356038!4d-36.6805342'
        )

        allow(Net::HTTP).to receive(:get_response).and_return(redirecionamento, resposta_final)

        resultado = described_class.call(texto)

        expect(resultado).to eq(
          latitude: -8.356038,
          longitude: -36.6805342,
          link: 'https://www.google.com/maps?q=-8.356038,-36.6805342',
          texto: 'Referência: https://www.google.com/maps?q=-8.356038,-36.6805342'
        )
      end
    end

    context 'quando o encurtador exige múltiplos redirecionamentos' do
      it 'segue todos os hops até chegar na resposta final' do
        texto = 'https://goo.gl/maps/abc123'

        primeiro_hop = resposta_redirecionamento('https://maps.app.goo.gl/def456')
        segundo_hop = resposta_redirecionamento('https://www.google.com/maps?q=-8.05,-34.9')

        allow(Net::HTTP).to receive(:get_response).and_return(primeiro_hop, segundo_hop, resposta_final)

        resultado = described_class.call(texto)

        expect(resultado[:latitude]).to eq(-8.05)
        expect(resultado[:texto]).to eq('https://www.google.com/maps?q=-8.05,-34.9')
        expect(Net::HTTP).to have_received(:get_response).exactly(3).times
      end
    end

    context 'quando o encurtador não resolve para um link com coordenadas' do
      it 'retorna nil' do
        texto = 'https://maps.app.goo.gl/semcoordenadas'

        allow(Net::HTTP).to receive(:get_response).and_return(resposta_final)

        resultado = described_class.call(texto)

        expect(resultado).to be_nil
      end
    end

    context 'quando a resolução do link entra em loop de redirecionamentos' do
      it 'para no limite máximo e retorna nil, em vez de travar' do
        texto = 'https://maps.app.goo.gl/loop'

        redirecionamento_infinito = resposta_redirecionamento('https://maps.app.goo.gl/loop')

        allow(Net::HTTP).to receive(:get_response).and_return(redirecionamento_infinito)

        resultado = described_class.call(texto)

        expect(resultado).to be_nil
        expect(Net::HTTP).to have_received(:get_response).exactly(described_class::MAX_REDIRECTS).times
      end
    end

    context 'quando ocorre um erro de rede ao resolver o link' do
      it 'não propaga a exceção e retorna nil' do
        texto = 'https://maps.app.goo.gl/erro'

        allow(Net::HTTP).to receive(:get_response).and_raise(SocketError, 'falha de rede')

        resultado = described_class.call(texto)

        expect(resultado).to be_nil
      end
    end

    context 'quando há pontuação colada no final do link' do
      it 'remove a pontuação antes de resolver, mas preserva a pontuação ao reescrever o texto' do
        texto = 'Fica perto da praça (https://maps.google.com/maps?q=-8.05,-34.9).'

        resultado = described_class.call(texto)

        expect(resultado[:latitude]).to eq(-8.05)
        expect(resultado[:longitude]).to eq(-34.9)
        expect(resultado[:texto]).to eq(
          'Fica perto da praça (https://www.google.com/maps?q=-8.05,-34.9).'
        )
      end
    end

    context 'quando o mesmo link aparece cercado de outro texto de ambos os lados' do
      it 'substitui apenas o link, preservando o texto antes e depois' do
        texto = 'Instalação nova - https://www.google.com/maps/@-8.05,-34.9,15z - sem número na casa'

        resultado = described_class.call(texto)

        expect(resultado[:texto]).to eq(
          'Instalação nova - https://www.google.com/maps?q=-8.05,-34.9 - sem número na casa'
        )
      end
    end
  end
end

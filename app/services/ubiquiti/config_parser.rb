# frozen_string_literal: true

# app/models/ubiquiti/config_parser.rb
module Ubiquiti
  module ConfigParser
    module_function

    # Converte texto de configuração key=value para hash
    #
    # @param config_text [String] conteúdo bruto do arquivo de configuração
    # @return [Hash{String => String}]
    def to_hash(config_text)
      config_text.each_line.with_object({}) do |line, hash|
        line = line.strip
        next if line.empty? || line.start_with?('#')

        key, value = line.split('=', 2)
        hash[key] = value
      end
    end

    # Converte hash para texto de configuração key=value
    #
    # @param config_hash [Hash] pares chave/valor
    # @return [String]
    def to_text(config_hash)
      "#{config_hash.map { |k, v| "#{k}=#{v}" }.join("\n")}\n"
    end
  end
end

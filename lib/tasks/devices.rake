# frozen_string_literal: true

# lib/tasks/devices.rake

namespace :devices do # rubocop:disable Metrics/BlockLength
  desc 'Realiza backup de configuração de todos os dispositivos Ponto'
  task backup: :environment do # rubocop:disable Metrics/BlockLength
    devices = Device.where(type: 'Devices::Ubiquiti')

    puts "Iniciando backup de #{devices.count} device(s)...\n\n"

    resultados = { salvo: [], ignorado: [], falhou: [] }

    devices.find_each do |device|
      result = Devices::BackupService.for(device).call
      label  = device.name.ljust(30)

      if result[:success]
        if result[:skipped]
          resultados[:ignorado] << device
          puts "  #{label} ignorado (sem alterações)"
        else
          resultados[:salvo] << device
          puts "  #{label} salvo (backup ##{result[:backup].id})"
        end
      else
        resultados[:falhou] << device
        puts "  #{label} FALHOU — #{result[:error]}"
      end
    end

    puts "\nResumo:"
    puts "  Salvos:   #{resultados[:salvo].count}"
    puts "  Ignorados: #{resultados[:ignorado].count}"
    puts "  Falhas:   #{resultados[:falhou].count}"

    if resultados[:falhou].any?
      puts "\nDevices com falha:"
      resultados[:falhou].each { |d| puts "  - #{d.name} (#{d.ip})" }
      exit 1
    end
  end
end

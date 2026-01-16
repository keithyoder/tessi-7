class EmitirNfcomJob < ApplicationJob
  queue_as :default

  def perform(fatura_id)
    Nfcom::Emitter.new.emitir(fatura_id)
  end
end

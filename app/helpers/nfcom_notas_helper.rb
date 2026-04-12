# frozen_string_literal: true

module NfcomNotasHelper
  def status_humanized
    I18n.t("nfcom_nota.statuses.#{status}")
  end
end

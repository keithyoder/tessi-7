# frozen_string_literal: true

module SearchHelper
  def current_page_params
    # Modify this list to whitelist url params for linking to the current page
    request.params.slice(
      'q',
      'filter',
      'sort',
      'adesao',
      'ativos',
      'renovaveis',
      'suspendiveis',
      'cancelaveis',
      'fisica',
      'juridica'
    )
  end
end

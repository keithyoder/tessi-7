# frozen_string_literal: true

module LiquidacoesHelper
  # Returns a CSS class based on performance comparison
  # @param statistics [Hash] statistics hash with :performance key
  # @return [String] Bootstrap class name
  def performance_class(statistics)
    return 'bg-light' if statistics[:performance].blank?

    statistics[:performance] == :acima ? 'bg-success text-white' : 'bg-warning text-white'
  end

  # Returns an arrow icon based on performance
  # @param statistics [Hash] statistics hash with :performance key
  # @return [String] Unicode arrow character
  def performance_arrow(statistics)
    return '' if statistics[:performance].blank?

    statistics[:performance] == :acima ? '↑' : '↓'
  end

  # Returns a human-readable performance text
  # @param statistics [Hash] statistics hash with :performance and :diferenca_percentual keys
  # @return [String] Formatted performance text
  def performance_text(statistics)
    return 'Sem dados' if statistics[:performance].blank?

    direction = statistics[:performance] == :acima ? 'acima' : 'abaixo'
    percentage = number_to_percentage(statistics[:diferenca_percentual].abs, precision: 1)

    "#{percentage} #{direction} da média"
  end

  # Returns the current view type based on params
  # @return [Symbol] :daily, :monthly, or :yearly
  def current_liquidacao_view
    if params[:mes].present?
      :monthly
    elsif params[:ano].present?
      :yearly
    else
      :daily
    end
  end

  # Returns a formatted title for the current view
  # @return [String] View title
  def liquidacao_view_title
    case current_liquidacao_view
    when :monthly
      "#{Date::MONTHNAMES[params[:mes].to_i]} de #{params[:ano]}"
    when :yearly
      'Visão Anual'
    else
      'Últimos 30 Dias'
    end
  end

  # Returns available years for selection (last 5 years + current)
  # @return [Array<Integer>] Array of years
  def liquidacao_available_years
    ((Date.current.year - 5)..Date.current.year).to_a.reverse
  end

  # Formats meio_liquidacao for display
  # @param meio [String] Payment method
  # @return [Hash] Hash with label and badge_class
  def payment_method_badge(meio)
    case meio
    when 'Dinheiro'
      { label: 'Dinheiro', badge_class: 'badge-success' }
    when 'CartaoCredito'
      { label: 'Cartão de Crédito', badge_class: 'badge-primary' }
    when 'RetornoBancario'
      { label: 'Retorno Bancário', badge_class: 'badge-info' }
    when 'Cheque'
      { label: 'Cheque', badge_class: 'badge-warning' }
    when 'Outros'
      { label: 'Outros', badge_class: 'badge-secondary' }
    else
      { label: meio || 'Não informado', badge_class: 'badge-secondary' }
    end
  end

  # Returns CSS class for chart based on view type
  # @return [String] Chart height class
  def chart_height_class
    case current_liquidacao_view
    when :monthly
      'chart-height-md'
    when :yearly
      'chart-height-lg'
    else
      'chart-height-sm'
    end
  end
end

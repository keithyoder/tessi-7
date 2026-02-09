# frozen_string_literal: true

module ApplicationHelper
  # def new_table_header(path)
  #  link_to '<i class="fa fa-plus" aria-hidden="true"></i>'.html_safe, path, class: "btn btn-sm btn-outline-dark"
  # end

  # def edit_button(path)
  #  link_to '<i class="fa fa-pencil fa-lg" aria-hidden="true"></i>'.html_safe, path, class: "btn btn-sm btn-outline-dark"
  # end

  # def index_button(path)
  #  link_to '<i class="fa fa-arrow-left" aria-hidden="true"></i>'.html_safe, path, class: "btn btn-sm btn-outline-dark"
  # end

  BOOTSTRAP_ALERT_MAP = {
    notice: :success,
    info: :info,
    warning: :warning,
    error: :danger
  }.freeze

  def online_button(up)
    if up
      'btn-success'
    else
      'btn-danger'
    end
  end

  def num_to_phone(num)
    if num.length == 11
      "(#{num[0..1]}) #{num[2..6]}-#{num[7..]}"
    else
      "(#{num[0..1]}) #{num[2..5]}-#{num[6..]}"
    end
  end

  def novo_botao(resource, params = {})
    return unless defined?(resource) && can?(:create, resource.model)

    link_to({ controller: resource.model_name.plural, params: params, action: :new },
            class: 'd-print-none btn btn-sm btn-outline-dark') do
      '<i class="bi bi-plus-square" aria-hidden="true"></i>'.html_safe
    end
  end

  def flash_message
    messages = ''
    %i[notice info warning error].each do |type|
      if flash[type]
        messages += "<div class=\"alert alert-#{BOOTSTRAP_ALERT_MAP[type]}\" role=\"alert\">#{flash[type]}</div>"
      end
    end
    messages.html_safe
  end

  def botao_salvar
    '<button name="button" type="submit" class="btn btn-primary"><i aria-hidden="true" class="bi bi-save"></i> Salvar </button>'.html_safe
  end

  def inline_pdf_css(name)
    Rails.root.join('app/assets/stylesheets', name).read
  end

  def edit_button(resource, options = {})
    return unless can?(:update, resource)

    css_class = options[:class] || 'btn btn-primary'
    text = options[:text] || 'Editar'
    icon = options[:icon] || 'bi-pencil'

    link_to edit_polymorphic_path(resource), class: css_class do
      concat content_tag(:i, '', class: "bi #{icon} me-1")
      concat text
    end
  end

  def back_button(path = :back, options = {})
    css_class = options[:class] || 'btn btn-outline-secondary'
    text = options[:text] || 'Voltar'
    icon = options[:icon] || 'bi-arrow-left'

    link_to path, class: css_class do
      concat content_tag(:i, '', class: "bi #{icon} me-1")
      concat text
    end
  end

  def delete_button(resource, options = {})
    return unless can?(:destroy, resource)

    css_class = options[:class] || 'btn btn-danger'
    text = options[:text] || 'Excluir'
    icon = options[:icon] || 'bi-trash'
    confirm_message = options[:confirm] || 'Tem certeza?'

    link_to polymorphic_path(resource),
            method: :delete,
            data: { confirm: confirm_message },
            class: css_class do
      concat content_tag(:i, '', class: "bi #{icon} me-1")
      concat text
    end
  end
end

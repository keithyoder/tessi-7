module FaturamentoHelper
  def diferenca_class(diferenca)
    if diferenca.positive?
      'text-success'  # Green
    elsif diferenca.negative?
      'text-danger'   # Red
    else
      'text-muted'    # Gray
    end
  end
end

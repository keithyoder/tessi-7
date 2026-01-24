# frozen_string_literal: true

module NavigationHelper
  def badge_if_positive(count, extra_classes: '')
    return unless count.positive?

    content_tag(
      :span,
      count,
      class: "badge rounded-pill bg-danger #{extra_classes}"
    )
  end
end

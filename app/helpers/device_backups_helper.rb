# frozen_string_literal: true

module DeviceBackupsHelper
  def diff_line_class(line)
    case line[0]
    when '+' then 'diff-add'
    when '-' then 'diff-remove'
    when '@' then 'diff-hunk'
    else          'diff-context'
    end
  end
end

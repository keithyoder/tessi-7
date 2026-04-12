# frozen_string_literal: true

# == Schema Information
#
# Table name: device_backups
#
#  id         :bigint           not null, primary key
#  checksum   :string           not null
#  config     :text             not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  device_id  :bigint           not null
#
# Indexes
#
#  index_device_backups_on_device_id  (device_id)
#
# Foreign Keys
#
#  fk_rails_...  (device_id => devices.id)
#
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

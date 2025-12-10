class Payment < ApplicationRecord
  belongs_to :consultation
  enum status: {pending: 0, approved: 1, failed: 2}
end

class Note < ApplicationRecord
  belongs_to :book
  belongs_to :chapter, optional: true
  validates :memo, presence: true
end

class Book < ApplicationRecord
  belongs_to :user
  has_many :notes, dependent: :destroy
  validates :title, presence: true
  has_many :chapters, dependent: :destroy
end

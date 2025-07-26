class Comment < ApplicationRecord
  has_many :likes, as: :likeable, dependent: :destroy
  belongs_to :post, optional: true
  belongs_to :comment, optional: true
  belongs_to :user
  belongs_to :parent, class_name: 'Comment', optional: true
  belongs_to :post_block, optional: true
  has_many :replies, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
  validates :content, presence: true

  has_many :children, class_name: 'Comment', foreign_key: :parent_id, dependent: :destroy
end

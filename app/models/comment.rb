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
  after_create :create_notification_for_post_author

  private

  def create_notification_for_post_author
    return if post.user == user  # 자기 글에 단 댓글은 알림 안 보냄

    Notification.create!(
      user: post.user,
      notifiable: self,
      message: "#{user.name} 님이 댓글을 남겼습니다.",
      read: false
    )
  end
end

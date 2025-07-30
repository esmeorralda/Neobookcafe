# app/models/user.rb
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :books, dependent: :destroy
  has_many :posts, dependent: :destroy  # posts user created
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
has_many :liked_posts, through: :likes, source: :likeable, source_type: "Post"
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, through: :bookmarks, source: :post  # posts user bookmarked
  has_many :book_intros, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :notes, dependent: :destroy
end

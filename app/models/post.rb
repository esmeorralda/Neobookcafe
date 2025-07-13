class Post < ApplicationRecord
  belongs_to :user
  has_many :post_blocks, -> { order(:position) }, dependent: :destroy
  has_many :comments, -> { where(parent_id: nil).order(created_at: :asc) }, dependent: :destroy
  enum :category, [ :thought, :discussion, :creation, :board ]
  enum :book_genre, [ :philosophy, :literature, :history, :society, :economy,
    :science_technology ]

  accepts_nested_attributes_for :post_blocks, allow_destroy: true
  after_commit :clear_post_cache

  def self.book_genre_korean
    {
      philosophy: "철학",
      literature: "문학",
      history: "역사",
      society: "사회",
      economy: "경제",
      science_technology: "과학/기술"
    }
  end

  def self.category_korean
    {
      thought: "감상문",
      discussion: "논설문",
      creation: "창작물",
      board: "자유게시글"
    }
  end

  def book_genre_kr
    return nil unless book_genre
    Post.book_genre_korean[book_genre.to_sym]
  end
  
  def category_kr
    return nil unless category
    Post.category_korean[category.to_sym]
  end
  
  def clear_post_cache
    Rails.cache.delete_matched("posts/*")
  end 
end

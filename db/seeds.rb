# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb

categories = [:thought, :discussion, :creation, :board]
book_genres = [:philosophy, :literature, :history, :society, :economy, :science_technology]

users = User.pluck(:id)

categories.each do |category|
  3.times do
    genre = book_genres.sample

    post = Post.create!(
      title: "#{category.to_s.humanize} - #{genre.to_s.humanize} 글 제목 #{SecureRandom.hex(3)}",
      book_title: "#{genre.to_s.humanize} 책 제목 #{SecureRandom.hex(2)}",
      book_author: "#{genre.to_s.humanize} 저자 #{SecureRandom.hex(2)}",
      user_id: users.sample,
      category: category,
      draft: false,
      allow_comments: true,
      book_genre: genre
    )

    rand(2..3).times.with_index(1) do |_, i|
      block_type = ["paragraph", "quote", "subtitle"].sample
      content = case block_type
                when "paragraph"
                  "문단 내용 예시 #{SecureRandom.hex(4)}"
                when "quote"
                  "인용문 예시 #{SecureRandom.hex(4)}"
                when "subtitle"
                  "부제목 예시 #{SecureRandom.hex(3)}"
                end

      PostBlock.create!(
        post_id: post.id,
        content: content,
        block_type: block_type,
        position: i
      )
    end
  end
end

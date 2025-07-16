class AddSearchIndexesToPosts < ActiveRecord::Migration[8.0]
   def change
    add_index :posts, :title
    add_index :posts, :book_title
    add_index :posts, :book_author
    add_index :users, :name
    add_index :post_blocks, :content, length: 191   # 💡 only for MySQL with TEXT column
  end
end

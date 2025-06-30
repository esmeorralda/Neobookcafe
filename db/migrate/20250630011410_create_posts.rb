class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.string :title
      t.string :book_title
      t.string :book_author
      t.string :book_genre
      t.string :category
      t.integer :save_count
      t.integer :like_count
      t.integer :view_count
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end

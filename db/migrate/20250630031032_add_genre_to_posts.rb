class AddGenreToPosts < ActiveRecord::Migration[8.0]
  def change
    remove_column :posts, :book_genre, :string
    add_column :posts, :book_genre, :integer, null: false, default: 0
  end
end

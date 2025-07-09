class AddPostBlockIdToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :post_block_id, :integer
    add_index :comments, :post_block_id
  end
end

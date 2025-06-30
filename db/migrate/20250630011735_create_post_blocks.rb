class CreatePostBlocks < ActiveRecord::Migration[8.0]
  def change
    create_table :post_blocks do |t|
      t.references :post, null: false, foreign_key: true
      t.string :block_type
      t.text :content
      t.integer :position

      t.timestamps
    end
  end
end

class RemoveHighlightFieldsFromPostBlocks < ActiveRecord::Migration[8.0]
  def change
    remove_column :post_blocks, :highlight_start, :integer
    remove_column :post_blocks, :highlight_end, :integer
  end
end

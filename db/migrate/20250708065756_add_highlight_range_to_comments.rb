class AddHighlightRangeToComments < ActiveRecord::Migration[8.0]
  def change
    add_column :comments, :highlight_start, :integer
    add_column :comments, :highlight_end, :integer
  end
end

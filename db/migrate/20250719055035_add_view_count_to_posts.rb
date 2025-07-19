class AddViewCountToPosts < ActiveRecord::Migration[8.0]
    unless column_exists?(:posts, :view_count)
      add_column :posts, :view_count, :integer, default: 0, null: false
    end
end

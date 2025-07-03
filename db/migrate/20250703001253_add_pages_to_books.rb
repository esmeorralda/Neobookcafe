class AddPagesToBooks < ActiveRecord::Migration[8.0]
  def change
    add_column :books, :total_pages, :integer
    add_column :books, :current_page, :integer
  end
end

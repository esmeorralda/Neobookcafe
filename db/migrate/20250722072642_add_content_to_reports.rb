class AddContentToReports < ActiveRecord::Migration[8.0]
  def change
    add_column :reports, :content, :text
  end
end

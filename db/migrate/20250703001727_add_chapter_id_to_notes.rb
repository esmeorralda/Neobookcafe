class AddChapterIdToNotes < ActiveRecord::Migration[8.0]
  def change
    add_reference :notes, :chapter, null: false, foreign_key: true
  end
end

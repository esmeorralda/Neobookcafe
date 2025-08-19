class MakeNotesChapterIdNullable < ActiveRecord::Migration[8.0]
   def up
    change_column_null :notes, :chapter_id, true
  end

end

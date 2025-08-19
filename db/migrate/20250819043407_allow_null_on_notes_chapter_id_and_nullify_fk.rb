class AllowNullOnNotesChapterIdAndNullifyFk < ActiveRecord::Migration[8.0]
    def up
    # 1) chapter_id를 NULL 허용 (이미 NULL 허용이어도 안전)
    change_column_null :notes, :chapter_id, true

    # 2) FK를 삭제 시 NULL로 전환 (이미 같은 설정이어도 재적용)
    remove_foreign_key :notes, :chapters if foreign_key_exists?(:notes, :chapters)
    add_foreign_key :notes, :chapters, on_delete: :nullify
  end

  def down
    # 되돌릴 때: 기본 FK로 복원 후 NOT NULL 강제
    remove_foreign_key :notes, :chapters if foreign_key_exists?(:notes, :chapters)
    add_foreign_key :notes, :chapters
    change_column_null :notes, :chapter_id, false
  end
end

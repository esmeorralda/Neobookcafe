class CreateChapters < ActiveRecord::Migration[6.1]
  def change
    create_table :chapters do |t|
      t.string :title
      t.integer :position  # 순서 지정
      t.references :book, foreign_key: true, null: true  # optional 관계

      t.timestamps
    end
  end
end

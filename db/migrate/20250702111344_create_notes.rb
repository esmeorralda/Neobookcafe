class CreateNotes < ActiveRecord::Migration[8.0]
  def change
    create_table :notes do |t|
      t.references :book, null: false, foreign_key: true
      t.integer :page_from
      t.integer :page_to
      t.string :chapter
      t.string :color
      t.text :memo

      t.timestamps
    end
  end
end

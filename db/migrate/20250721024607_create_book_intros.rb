class CreateBookIntros < ActiveRecord::Migration[8.0]
  def change
    create_table :book_intros do |t|
      t.references :user, null: false, foreign_key: true
      t.text :quote
      t.string :book_title
      t.string :author_name

      t.timestamps
    end
  end
end

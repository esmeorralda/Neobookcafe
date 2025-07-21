class AddSelfIntroToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :self_intro, :string
  end
end

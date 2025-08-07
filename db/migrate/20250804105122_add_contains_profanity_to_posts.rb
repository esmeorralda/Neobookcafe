class AddContainsProfanityToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :contains_profanity, :boolean, default: true
  end
end

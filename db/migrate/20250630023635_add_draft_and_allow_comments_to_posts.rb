class AddDraftAndAllowCommentsToPosts < ActiveRecord::Migration[8.0]
  def change
    add_column :posts, :draft, :boolean, default: false, null: false
    add_column :posts, :allow_comments, :boolean, default: true, null: true
  end
end

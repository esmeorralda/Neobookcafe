class ChangeCategoryToIntegerInPostBlocks < ActiveRecord::Migration[8.0]
  def change
    # 먼저 기존 string 컬럼을 제거하고
    remove_column :posts, :category, :string

    # integer 타입으로 새로 추가
    add_column :posts, :category, :integer, null: false, default: 0
  end
end

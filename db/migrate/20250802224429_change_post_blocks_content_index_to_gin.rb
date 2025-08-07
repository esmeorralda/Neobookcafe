class ChangePostBlocksContentIndexToGin < ActiveRecord::Migration[8.0]
 def up
    # 기존 인덱스 삭제 (이름 확인 필요, 기본명은 index_post_blocks_on_content)
    remove_index :post_blocks, name: 'index_post_blocks_on_content'

    # GIN 인덱스 생성
    execute <<-SQL
      CREATE INDEX idx_post_blocks_content_tsv ON post_blocks USING GIN (to_tsvector('simple', content));
    SQL
  end

  def down
    # GIN 인덱스 삭제
    execute <<-SQL
      DROP INDEX idx_post_blocks_content_tsv;
    SQL

    # 기존 btree 인덱스 다시 생성
    add_index :post_blocks, :content
  end
end

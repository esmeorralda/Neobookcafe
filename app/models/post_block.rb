class PostBlock < ApplicationRecord
  belongs_to :post
  # enum block_type: { paragraph: "paragraph", quote: "quote", question: "question", sub_title: "sub_title" }
  enum :block_type, [ :paragraph, :quote, :subtitle]
end


# db/strip_page_prefix_from_notes.rb
# 실행: bin/rails runner db/strip_page_prefix_from_notes.rb
pattern = /\A\s*p\.\s*\d+\s*[-–~]\s*\d+\s*[:\.\-·]?\s*/i

Note.find_each do |n|
  next unless n.memo.present?
  cleaned = n.memo.sub(pattern, '')
  next if cleaned == n.memo
  n.update_columns(memo: cleaned, updated_at: Time.current)
end
puts "done"

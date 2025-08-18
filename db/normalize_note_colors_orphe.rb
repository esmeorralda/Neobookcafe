# db/normalize_note_colors_orphe.rb
#!/usr/bin/env ruby
# 실행: bin/rails runner db/normalize_note_colors_orphe.rb

require_relative '../config/environment'

PALETTE = %w[#FFFFCD #E3FFDC #FFF0F8 #E1FAFF].freeze

# 이름 기반 매핑(기존 스크립트의 색상명 → 팔레트)
NAME_MAP = {
  'yellow' => '#FFFFCD',
  'orange' => '#FFFFCD',
  'green'  => '#E3FFDC',
  'pink'   => '#FFF0F8',
  'purple' => '#FFF0F8',
  'blue'   => '#E1FAFF'
}.freeze

user = %w[name username display_name nickname].detect { |c|
  User.column_names.include?(c)
}.then { |col|
  col ? User.find_by(col => '오르페') : nil
} or raise "유저 '오르페'를 찾을 수 없습니다."

scope = Note.where(user_id: user.id)

# 1) 이미 허용 팔레트이면 유지
# 2) 이름형 색상 → 매핑 적용
# 3) 그 외(널/기타)는 기본 '#E1FAFF'
updated = 0

scope.find_in_batches(batch_size: 1000) do |batch|
  batch.each do |n|
    next if n.color && PALETTE.include?(n.color)

    new_color =
      if n.color && NAME_MAP.key?(n.color)
        NAME_MAP[n.color]
      else
        '#E1FAFF'
      end

    n.update_columns(color: new_color) # 콜백/검증 우회, 대량처리에 적합
    updated += 1
  end
end

puts "[DONE] normalized=#{updated}, total=#{scope.count}"
puts "색상별 개수:"
puts Note.where(user_id: user.id).group(:color).count.inspect

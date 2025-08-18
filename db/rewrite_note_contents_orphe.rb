#!/usr/bin/env ruby
# frozen_string_literal: true
# 실행: bin/rails runner db/rewrite_note_contents_orphe.rb
# 목적:
#  - 각 노트를 '쪽수 요약 + 감상 + 개인적 인사이트' 형식으로 길게 덮어쓰기
#  - 책별 목표 개수(나미야 10 / 그 외 4) 미달 시 자동 보충
#  - 새 노트 색상은 허용 팔레트에서만 선택

begin
  require_relative '../config/environment'
rescue LoadError
  require 'pathname'
  app_root = Pathname.new(__dir__).join('..').realpath
  ENV['BUNDLE_GEMFILE'] ||= app_root.join('Gemfile').to_s
  require 'bundler/setup'
  require app_root.join('config', 'environment')
end

# ============ 스펙 ============
BOOK_SPECS = [
  { title: '나미야 잡화점의 기적', author: '히가시노 게이고', total_pages: 380, target_notes: 10, fiction: true },
  { title: '어린 왕자',             author: '앙투안 드 생텍쥐페리', total_pages: 120, target_notes: 4,  fiction: true },
  { title: '노인과 바다',           author: '어니스트 헤밍웨이',     total_pages: 200, target_notes: 4,  fiction: true },
  { title: '미움받을 용기',         author: '기시미 이치로·고가 후미타케', total_pages: 320, target_notes: 4, fiction: false }
].freeze

ALLOWED_COLORS = %w[#FFFFCD #E3FFDC #FFF0F8 #E1FAFF].freeze

# ============ 유틸 ============
def ensure_model(klass_name, table)
  Object.const_set(klass_name, Class.new(ActiveRecord::Base) { self.table_name = table }) unless Object.const_defined?(klass_name)
  Object.const_get(klass_name)
end

def find_user_named(name)
  user = nil
  %w[name username display_name nickname].each do |col|
    next unless User.column_names.include?(col)
    user = User.find_by(col => name)
    break if user
  end
  user
end

ensure_model('Book',  'books')  unless defined?(Book)
ensure_model('Note',  'notes')  unless defined?(Note)
HAS_CHAPTERS = ActiveRecord::Base.connection.table_exists?(:chapters)
ensure_model('Chapter', 'chapters') if HAS_CHAPTERS

def ensure_chapters_for(book, need:, user: nil)
  return [] unless HAS_CHAPTERS
  cols = Chapter.column_names
  exist = Chapter.where(cols.include?('book_id') ? { book_id: book.id } : {}).order(cols.include?('position') ? :position : :id).to_a
  (need - exist.size).times do |i|
    attrs = {}
    attrs[:book_id]  = book.id if cols.include?('book_id')
    label            = "제#{exist.size + i + 1}장"
    attrs[:title]    = label if cols.include?('title')
    attrs[:name]     = label if cols.include?('name') && !cols.include?('title')
    attrs[:position] = exist.size + i + 1 if cols.include?('position')
    attrs[:user_id]  = user.id if user && cols.include?('user_id')
    exist << Chapter.create!(attrs)
  end
  exist
end

def last_progress(book_id:, user_id:)
  scope = Note.where(book_id: book_id, user_id: user_id)
  last  = scope.order(:created_at, :id).last
  [last&.page_to.to_i, (last&.created_at || Time.current - 30.days)]
end

def clamp_len(s, min: 120, max: 260)
  return s if s.size.between?(min, max)
  if s.size < min
    pad = " 한 문장을 덮고 나니, 내 삶의 결도 아주 조금 바뀌었다."
    s += pad while s.size < min
    s[0...max]
  else
    s[0...max]
  end
end

# 책/쪽수 기반 장문 노트 생성기 (요약+감상+개인적 메모)
def long_note_for(title:, p_from:, p_to:, fiction:, idx:)
  span = "p.#{p_from}–#{p_to}"
  body =
    case title
    when '나미야 잡화점의 기적'
      seeds = [
        "#{span} 사연이 편지를 건너며 파문처럼 번진다. 작은 친절이 한 사람의 선택을 바꾸고, 그 선택이 다음 사람에게 이어진다. 내가 망설였던 일에도 이렇게 조용한 용기가 가능하다는 생각을 적어 둔다.",
        "#{span} 과거와 현재가 느슨하게 맞물리며 서로의 답장이 된다. ‘정답’보다 ‘함께 생각해 주는 시간’이 위로가 된다는 걸 배운다. 오늘 누군가의 질문을 급히 판단하지 않겠다고 다짐한다.",
        "#{span} 고민의 결은 다르지만 외로움의 온도는 비슷하다. 상점의 낡은 불빛처럼, 환하고 요란하진 않지만 오래 가는 위로가 있다. 나도 그런 불빛 하나쯤은 되고 싶다.",
        "#{span} 사소한 오해와 용기가 미세한 방향을 만든다. 어제의 실패가 오늘의 답장이 될 수 있다는 문장에 오래 머문다. 내 지난 선택들도 누군가에게 늦게 도착한 도움이 되길.",
        "#{span} ‘잘 산다는 것’은 정답을 맞히는 일이 아니라 서로의 시간을 견디게 해 주는 일. 내 일상의 빠른 판단을 잠시 낮추고 느리게 듣는 태도를 연습해 본다.",
        "#{span} 상점의 문틈으로 스며드는 새벽 공기 같은 장. 상처의 모양을 바꾸진 못해도 통증의 농도는 옅어질 수 있음을 배운다. 오늘의 불안도 지나갈 것이라 믿어 본다.",
        "#{span} 편지의 말끝마다 흔들림이 남아 있다. 그 떨림 때문에 한 사람이 구해진다. 불완전한 문장으로도 서로를 일으킬 수 있음을 기록해 둔다.",
        "#{span} 인연은 때로 우연을 닮았지만, 우연을 붙잡는 손은 분명 우리의 선택이다. 내가 흘려보낸 작은 호의들을 떠올리며, 다음 한 번은 더 머무르기로.",
        "#{span} 과거의 나에게 쓰는 편지 같은 챕터. 미뤄 둔 사과와 감사의 목록을 조용히 적는다. 오늘 한 통의 메시지로도 삶의 방향은 미세하게 달라질지 모른다.",
        "#{span} ‘기적’은 사건이 아니라 관계의 새로운 연결 방식이라는 생각. 덮고 나니 마음이 조금 따뜻해졌다. 나도 내 자리에서 답장을 계속 써 보려 한다."
      ]
      seeds[idx % seeds.size]
    when '어린 왕자'
      seeds = [
        "#{span} 길들임의 의미가 천천히 스민다. 소중함은 드문 사건이 아니라 함께 보낸 시간의 결에서 자란다. 내 일상의 장미가 누구인지, 물 주듯 돌아보아야겠다.",
        "#{span} 어른의 눈으론 보이지 않는 것들이 있다. 숫자로 환원되지 않는 가치들을 떠올린다. 오늘의 바쁨 속에서도 별 하나 올려다볼 틈을 남겨 두자.",
        "#{span} 사막의 고요가 문장 사이를 밝힌다. 말하지 못한 감정의 모래가 조금 가라앉는다. ‘중요한 건 눈에 보이지 않는다’는 오래된 진실을 다시 적는다.",
        "#{span} 여우의 조용한 충고가 마음을 붙잡는다. 기다림이 고통이 아니라 애정의 모양일 수 있다는 사실. 성급함을 줄이고, 만남의 리듬을 맞춰 보려 한다."
      ]
      seeds[idx % seeds.size]
    when '노인과 바다'
      seeds = [
        "#{span} 바다는 말을 아끼고 노인은 끝내 흔들리지 않는다. 패배와 존엄의 경계가 모호해질수록 인간의 크기가 드러난다. 나의 싸움도 결과보다 태도로 기억되길.",
        "#{span} 물결에 닳은 손등이 서사의 전부를 말한다. 노력은 때로 성과로 돌아오지 않지만, 실패가 인간을 축소시키지는 않는다. 견디는 법을 배운다.",
        "#{span} 외로운 싸움 뒤의 고요가 짙다. 누구도 보지 못한 순간을 버틴 자신만의 이유. 내가 지키고 싶은 이유 하나를 오늘도 다시 적는다.",
        "#{span} ‘사람은 패배하도록 만들어지지 않았다’는 말이 오래 남는다. 꺾여도 부서지지 않는 마음의 각도를 연습한다."
      ]
      seeds[idx % seeds.size]
    when '미움받을 용기'
      seeds = [
        "#{span} 과제의 분리가 한 발자국을 가볍게 한다. 타인의 기대를 내려놓을 때 관계의 호흡이 돌아온다. 오늘의 불필요한 책임을 조용히 내려놓는다.",
        "#{span} 인정욕구에서 자유로워질수록 삶의 방향이 선명해진다. 나의 과제와 남의 과제를 구분하는 연습을 메모한다. 작은 불편에서 시작한다.",
        "#{span} 공동체 감각은 거창한 헌신이 아니라 ‘기여하고 있다는 감각’에서 자란다. 내가 할 수 있는 구체적인 한 가지를 오늘 실천 목록에 올린다.",
        "#{span} 용기는 관계를 새로 쓰는 힘이다. 거절과 수용의 문장을 조금 더 솔직하게 다듬어 보겠다."
      ]
      seeds[idx % seeds.size]
    else
      base = fiction ?
        "#{span} 장면과 장면 사이의 숨이 느껴진다. 인물의 동기가 또렷해지고, 사소한 이미지들이 감정의 결을 만든다. 남는 한 줄을 적어 두며 내 삶에 겹쳐 본다." :
        "#{span} 핵심 개념이 사례와 만난다. 문장이 구조를 드러내며 이해의 층이 생긴다. 오늘의 실천 한 가지를 정리해 두니 기억이 오래간다."
      base
    end

  clamp_len(body, min: 140, max: 260)
end

user = find_user_named('오르페') or raise "유저 '오르페'를 찾을 수 없습니다."
note_has_content = Note.column_names.include?('content')

ActiveRecord::Base.transaction do
  BOOK_SPECS.each do |spec|
    book = Book.find_or_create_by!(user_id: user.id, title: spec[:title]) do |b|
      b.author       = spec[:author]
      b.total_pages  = spec[:total_pages]
      b.current_page = 0
    end
    book.update(total_pages: spec[:total_pages]) if book.total_pages.blank?

    chapters = ensure_chapters_for(book, need: spec[:target_notes], user: user)

    scope = Note.where(book_id: book.id, user_id: user.id).order(:created_at, :id)
    have  = scope.count
    need  = [spec[:target_notes] - have, 0].max

    # 부족하면 보충 생성
    if need > 0
      last_page, last_time = last_progress(book_id: book.id, user_id: user.id)
      total  = (book.total_pages || spec[:total_pages]).to_i
      chunks = spec[:target_notes]
      base_chunk = [(total.to_f / chunks).floor, 1].max
      rows = []
      need.times do |i|
        p_from = last_page + 1
        jitter = (base_chunk * 0.25).round
        span   = base_chunk + rand(-jitter..jitter)
        p_to   = [p_from + [span, 1].max - 1, total].min
        p_to   = [p_from, p_to].max
        last_time += rand(2..10).hours

        pos = have + i + 1
        chap_id = if chapters.any?
          chapters[(pos - 1) % chapters.size].id
        else
          nil
        end
        memo = long_note_for(title: book.title, p_from: p_from, p_to: p_to, fiction: spec[:fiction], idx: pos - 1)

        row = {
          book_id:    book.id,
          user_id:    user.id,
          page_from:  p_from,
          page_to:    p_to,
          chapter:    "제#{pos}장",
          chapter_id: chap_id,
          position:   pos,
          color:      ALLOWED_COLORS.sample,
          memo:       memo,
          created_at: last_time,
          updated_at: last_time
        }
        row[:content] = memo if note_has_content
        rows << row

        last_page = p_to
      end

      Note.insert_all!(rows)
      book.update(current_page: [book.current_page.to_i, rows.last[:page_to]].max)
      puts "[ADD] #{book.title} → +#{rows.size}개 보충 생성"
    end

    # 모든 노트 내용을 긴 형식으로 덮어쓰기
    notes = Note.where(book_id: book.id, user_id: user.id).order(:created_at, :id).to_a
    notes.each_with_index do |n, idx|
      p_from = n.page_from || (idx.zero? ? 1 : notes[idx - 1].page_to.to_i + 1)
      p_to   = n.page_to   || p_from
      memo   = long_note_for(title: book.title, p_from: p_from, p_to: p_to, fiction: spec[:fiction], idx: idx)
      attrs  = { memo: memo, updated_at: Time.current }
      attrs[:content] = memo if note_has_content
      n.update_columns(attrs) # validation 없이 빠르게
    end
    puts "[OK] #{book.title} → 총 #{notes.size}개(목표 #{spec[:target_notes]}) 장문으로 갱신"
  end
end

puts "완료! 확인 쿼리 예시 ↓"
puts "SELECT b.title, COUNT(n.id) AS notes, MIN(n.page_from) pf, MAX(n.page_to) pt FROM books b JOIN notes n ON n.book_id=b.id WHERE b.user_id=#{user.id} GROUP BY b.title;"

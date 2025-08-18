#!/usr/bin/env ruby
# frozen_string_literal: true
# 실행: bin/rails runner db/add_books_and_notes_for_orphe.rb
# - 유저 '오르페'에게 소설 3 + 비문학 1 추가
# - '나미야 잡화점의 기적' 노트 10개, 나머지 각 4개
# - 노트는 시간 흐름대로(created_at↑) 페이지도 증가(page_from/to↑)
# - notes.content 컬럼이 있으면 memo와 동일 내용 함께 저장

begin
  require_relative '../config/environment'
rescue LoadError
  require 'pathname'
  app_root = Pathname.new(__dir__).join('..').realpath
  ENV['BUNDLE_GEMFILE'] ||= app_root.join('Gemfile').to_s
  require 'bundler/setup'
  require app_root.join('config', 'environment')
end

require 'set'

# ---------- 유틸 ----------
def find_user_named(name)
  user = nil
  %w[name username display_name nickname].each do |col|
    next unless User.column_names.include?(col)
    user = User.find_by(col => name)
    break if user
  end
  user
end

def ensure_model(klass_name, table_name)
  unless Object.const_defined?(klass_name)
    Object.const_set(klass_name, Class.new(ActiveRecord::Base) { self.table_name = table_name })
  end
  Object.const_get(klass_name)
end

ensure_model('Book',  'books')  unless defined?(Book)
ensure_model('Note',  'notes')  unless defined?(Note)

HAS_CHAPTERS = ActiveRecord::Base.connection.table_exists?(:chapters)
ensure_model('Chapter', 'chapters') if HAS_CHAPTERS

def ensure_chapters_for(book, need:, user: nil)
  return [] unless HAS_CHAPTERS
  cols = Chapter.column_names
  exist = Chapter.where(cols.include?('book_id') ? {book_id: book.id} : {}).order(cols.include?('position') ? :position : :id).to_a
  make = [need - exist.size, 0].max
  made = []
  make.times do |i|
    attrs = {}
    attrs[:book_id]   = book.id if cols.include?('book_id')
    label = "제#{exist.size + i + 1}장"
    attrs[:title]     = label if cols.include?('title')
    attrs[:name]      = label if cols.include?('name') && !cols.include?('title')
    attrs[:position]  = exist.size + i + 1 if cols.include?('position')
    attrs[:user_id]   = user.id if user && cols.include?('user_id')
    made << Chapter.create!(attrs)
  end
  exist + made
end

def last_progress(book_id:, user_id:)
  scope = Note.where(book_id: book_id, user_id: user_id)
  last = scope.order(:created_at, :id).last
  [
    last&.page_to.to_i,            # 마지막으로 읽은 페이지
    (last&.created_at || Time.current - 30.days) # 마지막 작성 시각(없으면 과거로 시작)
  ]
end

def klog_for(title, fiction:, p_from:, p_to:)
  # 책별 키워드 기반 요약/소감 (짧은 문학체)
  base = case title
  when '나미야 잡화점의 기적'
    [
      "편지들이 서로를 건너가듯 마음이 이어진다.",
      "사소한 친절이 시간을 건너 기적이 된다.",
      "가장 평범한 사연에서 가장 따뜻한 결이 난다."
    ]
  when '어린 왕자'
    [
      "길들임의 의미가 천천히 스며든다.",
      "어른의 눈으론 보이지 않는 것이 있다.",
      "사막의 고요가 문장 사이를 밝혀 준다."
    ]
  when '노인과 바다'
    [
      "바다는 말이 없고, 노인은 끝내 흔들리지 않는다.",
      "패배가 아닌 존엄의 무게가 어깨에 얹힌다.",
      "물결에 닳은 손등이 서사의 전부를 말한다."
    ]
  when '미움받을 용기'
    [
      "과제의 분리가 한 발자국을 가볍게 한다.",
      "타인의 시선에서 나의 삶을 분리한다.",
      "용기는 관계를 새로 쓰는 힘이다."
    ]
  else
    fiction ?
      ["인물의 동기가 드러나며 긴장이 높아진다.", "이미지의 잔상이 오래간다.", "대화의 여백에서 감정이 움직인다."] :
      ["핵심 개념이 한 문단에 응축된다.", "사례가 개념을 선명하게 만든다.", "요약하니 구조가 또렷해진다."]
  end
  hook = base.sample
  "p.#{p_from}–#{p_to} #{hook}"
end

# ---------- 실행 파라미터 ----------
user = find_user_named('오르페') or raise "유저 '오르페'를 찾을 수 없습니다."
puts "[USER] id=#{user.id} name='오르페'"

BOOKS = [
  { title: '나미야 잡화점의 기적', author: '히가시노 게이고', total_pages: 380, target_notes: 10, fiction: true },
  { title: '어린 왕자',             author: '앙투안 드 생텍쥐페리', total_pages: 120, target_notes: 4,  fiction: true },
  { title: '노인과 바다',           author: '어니스트 헤밍웨이',     total_pages: 200, target_notes: 4,  fiction: true },
  { title: '미움받을 용기',         author: '기시미 이치로·고가 후미타케', total_pages: 320, target_notes: 4, fiction: false }
]

note_has_content = Note.column_names.include?('content')

ActiveRecord::Base.transaction do
  BOOKS.each do |spec|
    book = Book.find_or_create_by!(user_id: user.id, title: spec[:title]) do |b|
      b.author       = spec[:author]
      b.total_pages  = spec[:total_pages]
      b.current_page = 0
    end
    # 비어있으면 메타 보강
    book.update(total_pages: spec[:total_pages]) if book.total_pages.blank?

    # 필요한 만큼 챕터 확보(있을 때만)
    chapters = ensure_chapters_for(book, need: spec[:target_notes], user: user)

    have = Note.where(book_id: book.id, user_id: user.id).count
    need = [spec[:target_notes] - have, 0].max
    puts "[BOOK] #{book.title} (have=#{have}, need=#{need})"
    next if need.zero?

    # 진행 상황/시간 기준점
    last_page, last_time = last_progress(book_id: book.id, user_id: user.id)

    total = (book.total_pages || spec[:total_pages] || 200).to_i
    chunks = spec[:target_notes]
    base_chunk = [(total.to_f / chunks).floor, 1].max

    rows = []
    need.times do |i|
      # 페이지 진행: 직전의 마지막 페이지 이후로 이어붙이기
      p_from = last_page + 1
      # 흔들림(±)을 줘서 자연스럽게
      jitter = (base_chunk * 0.3).round
      span   = base_chunk + rand(-jitter..jitter)
      p_to   = [p_from + [span, 1].max - 1, total].min
      p_to   = [p_from, p_to].max

      # 시간 진행: 마지막 작성시각 이후 1~12시간 간격
      last_time += rand(1..12).hours

      # 챕터/포지션
      pos = have + i + 1
      chap_label = "제#{((pos - 1) % (chapters.any? ? chapters.size : spec[:target_notes])) + 1}장"
      chap_id = chapters.any? ? chapters[(pos - 1) % chapters.size].id : pos

      text = klog_for(book.title, fiction: spec[:fiction], p_from: p_from, p_to: p_to)

      row = {
        book_id:    book.id,
        user_id:    user.id,
        page_from:  p_from,
        page_to:    p_to,
        chapter:    chap_label,
        chapter_id: chap_id,
        position:   pos,
        color:      %w[yellow pink green blue orange purple].sample,
        memo:       text,
        created_at: last_time,
        updated_at: last_time
      }
      row[:content] = text if note_has_content
      rows << row

      # 다음 루프를 위한 기준 업데이트
      last_page = p_to
    end

    Note.insert_all!(rows)
    # 진행 페이지를 현재 페이지로 업데이트(최대치 보호)
    new_current = [book.current_page.to_i, last_page].max
    book.update(current_page: [new_current, total].min)
    puts "[NOTE] #{book.title} → +#{rows.size}개, 마지막 p=#{last_page}, 최신시각=#{rows.last[:created_at]}"
  end
end

puts "완료! 확인 쿼리 예시 ↓"
puts "SELECT title, (SELECT COUNT(*) FROM notes n WHERE n.book_id = books.id AND n.user_id = #{user.id}) AS notes_cnt FROM books WHERE user_id = #{user.id} ORDER BY title;"
puts "SELECT book_id, MIN(page_from) AS min_pf, MAX(page_to) AS max_pt, MIN(created_at) AS first_at, MAX(created_at) AS last_at FROM notes WHERE user_id = #{user.id} GROUP BY book_id;"

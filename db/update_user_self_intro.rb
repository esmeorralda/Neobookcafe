
begin
  require_relative '../config/environment'
rescue LoadError
  # ruby로 직접 실행할 때 환경 로드
  require 'pathname'
  app_root = Pathname.new(__dir__).join('..').realpath
  ENV['BUNDLE_GEMFILE'] ||= app_root.join('Gemfile').to_s
  require 'bundler/setup'
  require app_root.join('config', 'environment')
end

# 로그 출력(원하면 주석 처리)
ActiveRecord::Base.logger = Logger.new($stdout)

ids = (6..25).to_a
intros = [
  '책 한 페이지로 오늘을 리셋해요.',
  '커피 향 따라 문장에 잠수합니다.',
  '느리게 읽어도 오래 남는 독서를 좋아해요.',
  '퇴근 후 10분, 책으로 마음을 환기합니다.',
  '소설은 모험이고 에세이는 휴식이에요.',
  '생각을 메모하고 대화를 모으는 북카페러입니다.',
  '다다익선(多多益善) - 좋은 문장은 많을수록 더 반짝인다.',
  '낯선 문장을 만나면 먼저 인사해요.',
  '오늘의 기분을 책갈피에 살짝 눌러 두었습니다.',
  '한 권을 끝까지, 내 속도로 완독합니다.',
  '책 속 문장으로 스스로를 업데이트해요.',
  '토론으로 생각의 여백을 넓히는 편입니다.',
  '문장 수집이 취미라서 메모앱이 늘 바빠요.',
  '오월동주(吳越同舟) - 다른 생각도 책 한 권으로 같은 배를 탄다.',
  '조용한 오후, 커피 한 잔과 한 문장으로 버팁니다.',
  '읽고 쓰고 나누며 하루를 단단히 묶어요.',
  '웹소설로 쉬고 인문서로 깊어지는 타입입니다.',
  '좋아하는 문장을 소리 내어 읽으면 마음이 정리돼요.',
  '느슨하지만 꾸준히, 매일 한 줄은 꼭 읽습니다.',
  '오늘 더 나은 내가 되도록 책과 함께 걸어요.'
]

raise "IDs(#{ids.size})와 문구(#{intros.size}) 개수가 다릅니다." unless ids.size == intros.size

ActiveRecord::Base.transaction do
  ids.zip(intros).each do |id, intro|
    affected = User.where(id: id).update_all(self_intro: intro)
    puts "[OK] id=#{id} (updated=#{affected}) → #{intro}"
  end
end

puts "완료! 확인:"
puts "SELECT id, self_intro FROM users WHERE id BETWEEN 6 AND 25 ORDER BY id;"

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

range_ids  = (6..25).to_a
reset_mode = ENV['RESET'].to_s == '1'

# ✅ 한국 독자에게 널리 알려진 소설/고전의 대표적 명문장 (≤ 90자 내)
POOL = [
  {book_title: '모비 딕', author_name: '허먼 멜빌', quote: '나를 이슈마엘이라 부르라.'},
  {book_title: '두 도시 이야기', author_name: '찰스 디킨스', quote: '그것은 최선의 시대요, 최악의 시대였다.'},
  {book_title: '안나 카레니나', author_name: '레프 톨스토이', quote: '행복한 가정은 서로 비슷하고, 불행은 제각각이다.'},
  {book_title: '위대한 개츠비', author_name: 'F. 스콧 피츠제럴드', quote: '그래도 우리는 앞으로 나아간다, 거대한 물결을 거슬러.'},
  {book_title: '오만과 편견', author_name: '제인 오스틴', quote: '재산 많은 독신 남자는 아내가 필요하다는 진리.'},
  {book_title: '제인 에어', author_name: '샬럿 브론테', quote: '나는 새가 아니고, 그물도 나를 가둘 수 없다.'},
  {book_title: '폭풍의 언덕', author_name: '에밀리 브론테', quote: '우리의 혼은 같은 것으로 빚어졌다.'},
  {book_title: '크리스마스 캐럴', author_name: '찰스 디킨스', quote: '신은 우리 모두를 축복하시길.'},
  {book_title: '보물섬', author_name: '로버트 루이스 스티븐슨', quote: '요호호, 럼주 한 병!'},
  {book_title: '이상한 나라의 앨리스', author_name: '루이스 캐럴', quote: '우리는 모두 여기서 미쳤지.'},
  {book_title: '거울 나라의 앨리스', author_name: '루이스 캐럴', quote: '점점 더 이상해지고 있어.'},
  {book_title: '피터 팬', author_name: 'J. M. 배리', quote: '영원히 자라지 않는 아이.'},
  {book_title: '톰 소여의 모험', author_name: '마크 트웨인', quote: '페인트칠도 모험이 될 수 있다.'},
  {book_title: '허클베리 핀의 모험', author_name: '마크 트웨인', quote: '난 다시는 문명인이 되지 않겠어.'},
  {book_title: '레 미제라블', author_name: '빅토르 위고', quote: '가장 어두운 밤도 끝나고 해는 떠오른다.'},
  {book_title: '몬테크리스토 백작', author_name: '알렉상드르 뒤마', quote: '인간의 지혜: 기다리고, 희망하라.'},
  {book_title: '데미안', author_name: '헤르만 헤세', quote: '새는 알에서 나오려고 싸운다.'},
  {book_title: '싯다르타', author_name: '헤르만 헤세', quote: '지식은 전해지지만, 깨달음은 스스로 얻는다.'},
  {book_title: '노인과 바다', author_name: '어니스트 헤밍웨이', quote: '인간은 패배하도록 만들어지지 않았다.'},
  {book_title: '위대한 유산', author_name: '찰스 디킨스', quote: '묻지 않으면 거짓말도 듣지 않는다.'},
  {book_title: '드라큘라', author_name: '브람 스토커', quote: '들어보게, 밤의 아이들이여.'},
  {book_title: '프랑켄슈타인', author_name: '메리 셸리', quote: '나는 두렵지 않다, 그러니 강하다.'},
  {book_title: '오즈의 마법사', author_name: '프랭크 바움', quote: '집만 한 곳은 없다.'},
  {book_title: '어둠의 심연', author_name: '조지프 콘래드', quote: '공포! 공포!'},
  {book_title: '타임 머신', author_name: 'H. G. 웰스', quote: '우리는 늘 현재를 빠져나가려 한다.'},
  {book_title: '지킬 박사와 하이드', author_name: 'R. L. 스티븐슨', quote: '한 사람 안에 둘의 얼굴이 산다.'},
  {book_title: '햄릿', author_name: '윌리엄 셰익스피어', quote: '사느냐 죽느냐, 그것이 문제로다.'},
  {book_title: '베니스의 상인', author_name: '윌리엄 셰익스피어', quote: '자비는 힘보다 높이 흐른다.'},
  {book_title: '줄리어스 시저', author_name: '윌리엄 셰익스피어', quote: '브루투스, 너마저!'},
  {book_title: '오셀로', author_name: '윌리엄 셰익스피어', quote: '질투는 녹색 눈의 괴물.'},
  {book_title: '걸리버 여행기', author_name: '조너선 스위프트', quote: '사람은 오래 살기를 바라나 늙기는 원치 않는다.'},
  {book_title: '해저 2만 리', author_name: '쥘 베른', quote: '바다는 모든 것을 품는다.'},
  {book_title: '셜록 홈즈의 모험', author_name: '아서 코난 도일', quote: '게임이 시작됐군.'},
  {book_title: '바람과 함께 사라지다', author_name: '마거릿 미첼', quote: '내일은 내일의 태양이 뜬다.'},
  {book_title: '호빗', author_name: 'J. R. R. 톨킨', quote: '땅속 굴에 한 호빗이 살고 있었다.'},
  {book_title: '반지의 제왕', author_name: 'J. R. R. 톨킨', quote: '모든 반지를 지배하는 반지 하나.'},
  {book_title: '1984', author_name: '조지 오웰', quote: '빅 브라더가 너를 지켜보고 있다.'},
  {book_title: '동물 농장', author_name: '조지 오웰', quote: '모든 동물은 평등하다.'},
  {book_title: '연금술사', author_name: '파울로 코엘료', quote: '간절히 원하면 온 우주가 도와준다.'},
  {book_title: '어린 왕자', author_name: '앙투안 드 생텍쥐페리', quote: '가장 중요한 것은 눈에 보이지 않는다.'},
  {book_title: '변신', author_name: '프란츠 카프카', quote: '어느 날 아침, 그는 거대한 벌레로 변해 있었다.'},
  {book_title: '삼총사', author_name: '알렉상드르 뒤마', quote: '하나를 위하여 모두, 모두를 위하여 하나!'},
  {book_title: '이방인', author_name: '알베르 카뮈', quote: '오늘 엄마가 죽었다. 어쩌면 어제.'},
  {book_title: '호밀밭의 파수꾼', author_name: 'J. D. 샐린저', quote: '나는 호밀밭의 파수꾼이 되고 싶다.'},
  {book_title: '파리대왕', author_name: '윌리엄 골딩', quote: '짐승은 우리 안에 있었다.'},
  {book_title: '향수', author_name: '파트릭 쥐스킨트', quote: '그에게는 천재적인 후각이 있었다.'},
  {book_title: '백년의 고독', author_name: '가브리엘 가르시아 마르케스', quote: '오랜 세월 후, 그는 얼음을 보러 가던 날을 떠올렸다.'},
  {book_title: '날개', author_name: '이상', quote: '날개야 돋아라.'},
  {book_title: '인간 실격', author_name: '다자이 오사무', quote: '부끄럼 많은 생애를 보냈습니다.'},
  {book_title: '마음', author_name: '나쓰메 소세키', quote: '나는 그를 선생님이라 불렀다.'},
  {book_title: '설국', author_name: '가와바타 야스나리', quote: '국경의 긴 터널을 빠져나오자, 눈의 고장이었다.'},
  {book_title: '나는 고양이로소이다', author_name: '나쓰메 소세키', quote: '나는 고양이로소이다. 이름은 아직 없다.'},
  {book_title: '페스트', author_name: '알베르 카뮈', quote: '인간에게는 경멸보다 존경할 것이 더 많다.'},
  {book_title: '해리 포터와 마법사의 돌', author_name: 'J. K. 롤링', quote: '살아남은 아이.'},
  {book_title: '나니아 연대기', author_name: 'C. S. 루이스', quote: '옷장 문을 열자, 다른 세계가 있었다.'},
  {book_title: '셜록 홈즈의 회상록', author_name: '아서 코난 도일', quote: '기초적인 일이지, 왓슨.'},
  {book_title: '토지', author_name: '박경리', quote: '땅은 사람을 배반하지 않는다.'},
{book_title: '광장', author_name: '최인훈', quote: '나는 어디에도 속하지 못한 채 이 광장에 서 있다.'},
{book_title: '태백산맥', author_name: '조정래', quote: '한 맺힌 사람들의 역사가 산맥처럼 이어졌다.'},
{book_title: '무정', author_name: '이광수', quote: '눈물은 인간의 마음을 씻어내는 샘물이다.'}

].freeze

need_total = range_ids.size * 3
raise "POOL(#{POOL.size})이 부족합니다: 최소 #{need_total}개 필요" if POOL.size < need_total

ActiveRecord::Base.transaction do
  if reset_mode
    BookIntro.where(user_id: range_ids).delete_all
    puts "[RESET] 기존 book_intros 삭제 (user_id: #{range_ids.first}..#{range_ids.last})"
  end

  used_global_titles = Set.new
  pool_queue = POOL.shuffle

  range_ids.each do |uid|
    existing_titles = BookIntro.where(user_id: uid).pluck(:book_title).to_set
    picks = []

    while picks.size < 3
      raise "POOL 소진으로 3개를 채울 수 없습니다. 현재 picks=#{picks.size}" if pool_queue.empty?
      item = pool_queue.shift
      title = item[:book_title]
      next if existing_titles.include?(title)
      next if used_global_titles.include?(title)
      picks << item
      used_global_titles << title
    end

    rows = picks.map do |h|
      { user_id: uid, book_title: h[:book_title], author_name: h[:author_name],
        quote: h[:quote], created_at: Time.current, updated_at: Time.current }
    end

    BookIntro.insert_all!(rows)
    puts "[OK] user_id=#{uid} → +#{rows.size}개 (전역 누적: #{used_global_titles.size}/#{need_total})"
  end
end

puts "완료! 확인 쿼리 ↓"
puts "SELECT user_id, book_title, author_name, quote FROM book_intros WHERE user_id BETWEEN 6 AND 25 ORDER BY user_id, id;"

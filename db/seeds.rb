# db/seeds.rb

nicknames = [
  "스프링",    # 소크라테스 + 크로스오버
  "밤열두시",    # 감성적
  "오로모스",    # 그리스어 'oros'(산) 변형
  "책오리",      # 단순 직관
  "네페리온",    # 'nephelion'(구름+태양)
  "감자",      # 유머 감성
  "파이값",      # 수학 상징 π
  "루멘",        # 빛의 단위
  "별밤길",      # 시적인 느낌
  "디오스",      # 그리스어 '신'
  "아루",        # 짧고 귀여움
  "프로톤",      # 물리학 입자
  "몽유도원",    # 몽유도원도(꿈속 낙원)
  "제로원",      # 0과 1의 조합
  "키리아",      # 그리스어 'kyrios'(주인)
  "냉소펭귄",    # 유머+동물
  "시네마틱",    # 영화적인
  "헤르모",      # 그리스 신 Hermes 변형
  "푸른책",    # 감성
  "오르페"      # 그리스 신 Orpheus 변형
]

nicknames.each_with_index do |nickname, i|
  email = "tester#{i + 1}@example.com"

  unless User.exists?(email: email)
    User.create!(
      email: email,
      password: "password",
      password_confirmation: "password",
      name: nickname
    )
    puts "✅ Created: #{email} (#{nickname})"
  else
    puts "⚠️ Skipped: #{email} already exists"
  end
end

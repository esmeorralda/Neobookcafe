require 'open3'
require 'shellwords'
require 'json'

# 체크할 문장 입력
text_to_check = "너 진짜 씨발 같은 새끼야"

# Node.js 스크립트
node_script = <<~JS
  const {
    check,
    general,
    minor,
    sexual,
    belittle,
    race,
    parents,
    foreign,
    special,
    politics,
  } = require('korcen');

  const input = process.argv[2] || "";

  console.log(JSON.stringify({
    input,
    flagged: check(input),
    general: general(input),
    minor: minor(input),
    sexual: sexual(input),
    belittle: belittle(input),
    race: race(input),
    parents: parents(input),
    foreign: foreign(input),
    special: special(input),
    politics: politics(input)
  }));
JS

# 임시 Node.js 파일 경로
tmp_js_path = "tmp_korcen_check.js"
File.write(tmp_js_path, node_script)

# Node 실행 커맨드
cmd = "node #{tmp_js_path} #{Shellwords.escape(text_to_check)}"
puts "실행 커맨드: #{cmd}"

# 실행
stdout, stderr, status = Open3.capture3(cmd)

if status.success?
  result = JSON.parse(stdout)

  puts "\n📌 감지된 문제 요약:\n"

  category_messages = {
    "flagged" => "🚨 비속어 포함 여부",
    "general" => "💢 일반적인 욕설",
    "minor" => "🔸 사소한 욕설",
    "sexual" => "❗ 성적 발언",
    "belittle" => "⬇️ 비하 발언",
    "race" => "🔻 인종차별 발언",
    "parents" => "👪 부모 관련 욕설",
    "foreign" => "🌍 외국어 욕설",
    "special" => "✨ 특수 문자 또는 이모지",
    "politics" => "🏛️ 정치 관련 표현"
  }

  category_messages.each do |key, label|
    value = result[key]
    if value == true
      puts "#{label}: 있음"
    elsif value.is_a?(Array) && !value.empty?
      puts "#{label}: 있음 (#{value.join(', ')})"
    end
  end

  puts "\n🔎 원본 문장: #{result["input"]}"
  puts "🚨 전체 비속어 포함 여부: #{result["flagged"] ? 'Yes' : 'No'}"
else
  puts "Node.js 실행 에러:"
  puts stderr
end

File.delete(tmp_js_path) if File.exist?(tmp_js_path)

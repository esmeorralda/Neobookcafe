require "net/http"
require "json"
require "uri"

api_key = ENV["OPENAI_API_KEY"]
uri = URI("https://api.openai.com/v1/moderations")

input_text = " "
# 따옴표(" '), 엔터(\n), 탭(\t) 모두 제거하고 한 문장으로 붙이기
clean_text = input_text.delete("\"'\n\t").gsub(/\s+/, " ").strip

# 2) JSON 요청용 문자열 생성
request_body = {
  model: "omni-moderation-latest",
  input: clean_text
}.to_json


http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Post.new(uri.path, {
  "Content-Type" => "application/json",
  "Authorization" => "Bearer #{api_key}"
})

request.body = request_body
response = http.request(request)
result = JSON.parse(response.body)

# 디버깅용 전체 응답 출력
puts JSON.pretty_generate(result)


# 커스텀 유해성 기준 적용
if result && result["results"]
  scores = result["results"][0]["category_scores"]
  flagged_category = scores.find { |category, score| score.to_f >= 0.10 }

  if flagged_category
    name, score = flagged_category
    puts "[⚠️ 유해 콘텐츠 감지됨]"
    puts "→ 이유: '#{name}' 점수가 #{(score.to_f * 100).round(2)}% 이기 때문입니다."
  else
    puts "안전한 콘텐츠입니다."
  end
else
  puts "결과를 분석할 수 없습니다."
end

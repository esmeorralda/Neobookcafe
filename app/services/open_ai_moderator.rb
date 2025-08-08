# lib/moderation_checker.rb
require "net/http"
require "json"
require "uri"

module ModerationChecker
  def self.check(text)
    api_key = ENV["OPENAI_API_KEY"]
    uri = URI("https://api.openai.com/v1/moderations")

    clean_text = text.delete("\"'\n\t").gsub(/\s+/, " ").strip

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

    if result && result["results"]
      scores = result["results"][0]["category_scores"]
      flagged = scores.find { |_, score| score.to_f >= 0.10 }
      return flagged # [category_name, score] 또는 nil
    else
      nil
    end
  rescue => e
    Rails.logger.error("Moderation API Error: #{e.message}")
    nil
  end
end

require "openai"

OPENAI_KEY = ENV["OPENAI_API_KEY"] || Rails.application.credentials.dig(:openai, :api_key)

if OPENAI_KEY.blank?
  Rails.logger.warn("[OpenAI] Missing API key. Set ENV['OPENAI_API_KEY'] or credentials.openai.api_key")
else
  # 공식 SDK는 api_key 키워드를 사용하거나, ENV만 있어도 동작합니다.
  Rails.application.config.x.openai_client = OpenAI::Client.new(api_key: OPENAI_KEY)
  # 또는 ENV만 쓰고 싶다면 ↓ 로도 OK (ENV["OPENAI_API_KEY"]가 설정돼 있어야 함)
  # Rails.application.config.x.openai_client = OpenAI::Client.new
end

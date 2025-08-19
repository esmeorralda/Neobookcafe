# frozen_string_literal: true
module CacheKeyHelper
  module_function

  # posts 전용 버전 키
  def vposts_key(bucket, **opts)
    ver   = CacheVersion.get(:posts) # ← 버전 번호
    # 옵션들을 정렬·직렬화해서 키를 안정적으로 만듦
    parts = opts.compact
               .sort_by { |k, _| k.to_s }
               .map { |k, v| "#{k}=#{Array(v).join(',')}" }
               .join("|")
    "v#{ver}:posts:#{bucket}:#{parts}"
  end
end

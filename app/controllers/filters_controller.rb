require "open3"
require "shellwords"
require "json"

class FiltersController < ApplicationController
  def check
    @input = params[:text]

    if @input.blank?
      @flagged = false
      @reasons = []
      return
    end

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

    tmp_js_path = Rails.root.join("tmp/tmp_korcen_check.js")
    File.write(tmp_js_path, node_script)

    cmd = "node #{tmp_js_path} #{Shellwords.escape(@input)}"
    stdout, stderr, status = Open3.capture3(cmd)
    File.delete(tmp_js_path) if File.exist?(tmp_js_path)

    if status.success?
      result = JSON.parse(stdout)
      @flagged = result["flagged"]
      @reasons = []

      categories = {
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

      categories.each do |key, label|
        if result[key] == true || (result[key].is_a?(Array) && !result[key].empty?)
          @reasons << label
        end
      end
    else
      @flagged = false
      @reasons = [ "Node.js 실행 오류: #{stderr}" ]
    end
  end
end

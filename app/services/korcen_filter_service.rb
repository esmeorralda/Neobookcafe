# app/services/korcen_filter_service.rb
require 'open3'
require 'shellwords'
require 'json'
module KorcenFilterService
  class << self
    def analyze_sentence(sentence)
      return nil if sentence.blank?

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

      cmd = "node #{tmp_js_path} #{Shellwords.escape(sentence)}"
      stdout, stderr, status = Open3.capture3(cmd)


      File.delete(tmp_js_path) if File.exist?(tmp_js_path)

      return nil unless status.success?

      result = JSON.parse(stdout)
      return nil unless result["flagged"]

      {
        sentence: result["input"],
        flagged: result["flagged"],
        categories: {
          general: result["general"],
          minor: result["minor"],
          sexual: result["sexual"],
          belittle: result["belittle"],
          race: result["race"],
          parents: result["parents"],
          foreign: result["foreign"],
          special: result["special"],
          politics: result["politics"]
        }
      }
    end

    def analyze_text(full_text)
      return [] if full_text.blank?

      sentences = full_text.split(/[.?!]\s*/).map(&:strip).reject(&:empty?)
      flagged_results = []

      sentences.each do |sentence|
        result = analyze_sentence(sentence)
        flagged_results << result if result
      end

      flagged_results
    end
  end
end

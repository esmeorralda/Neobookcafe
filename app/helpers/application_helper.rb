module ApplicationHelper
    def time_ago_in_korean(time)
        seconds = Time.current - time
    
        case seconds
        when 0..59
           "방금 전"
        when 60..3599
          "#{(seconds / 60).to_i}분 전"
        when 3600..86_399
          "#{(seconds / 3600).to_i}시간 전"
        when 86_400..2_592_000
          "#{(seconds / 86_400).to_i}일 전"
        when 2_592_001..31_536_000
          "#{(seconds / 2_592_000).to_i}달 전"
        else
          "#{(seconds / 31_536_000).to_i}년 전"
        end
      end
end

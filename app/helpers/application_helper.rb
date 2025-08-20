module ApplicationHelper
  def show_dashboard_link?
    return false unless user_signed_in?

    # 1) credentials 우선
    creds = Rails.application.credentials.dig(:admin_emails)
    # 2) 없으면 ENV 사용
    envs  = ENV.fetch("ADMIN_EMAILS", "")
               .split(",")
               .map { |e| e.strip.downcase }
               .reject(&:blank?)

    allowed = Array(creds).map(&:downcase) + envs
    allowed.include?(current_user.email.to_s.downcase)
  end
  
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end
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

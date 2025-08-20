class ApplicationController < ActionController::Base
   # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
   before_action :configure_permitted_parameters, if: :devise_controller?

  allow_browser versions: :modern
   include Pagination
    helper_method :page_no, :per_page

  protected
  def configure_permitted_parameters
    # 회원가입 시 name 허용
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    # 계정 수정 시 name 허용 (선택)
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end
end

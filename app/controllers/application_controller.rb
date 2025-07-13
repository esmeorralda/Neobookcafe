class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
   include Pagination
    helper_method :page_no, :per_page 
  protected

  # 로그인 성공 후 루트로 이동
  def after_sign_in_path_for(resource)
    root_path
  end

  # 로그아웃 후에도 루트로 이동 (선택사항)
  # def after_sign_out_path_for(resource_or_scope)
  #   root_path
  # end 


  def configure_permitted_parameters
    # 회원가입 시 name 허용
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
    # 계정 수정 시 name 허용 (선택)
    devise_parameter_sanitizer.permit(:account_update, keys: [:name])
  end


end

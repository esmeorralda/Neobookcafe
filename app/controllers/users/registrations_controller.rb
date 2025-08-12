# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
    # 비번 변경 후 flash 타입/문구와 이동 경로를 원하는 대로
    def update
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)
  
      if update_resource(resource, account_update_params)
        # ✅ 기본은 notice지만, alert로 띄우고 싶다면 이렇게:
        flash[:alert] = I18n.t("devise.registrations.updated") # 문구는 아래 i18n에서 수정 가능
        # 비밀번호 바뀐 뒤 재로그인 유지
        bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
        respond_with resource, location: after_update_path_for(resource)
      else
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end
  
    protected
  
    # ✅ 리다이렉트 위치 커스텀(원하는 경로로)
    def after_update_path_for(resource)
      root_path
    end
  end
  
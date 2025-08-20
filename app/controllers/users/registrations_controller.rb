# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
   respond_to :html
    # 비번 변경 후 flash 타입/문구와 이동 경로를 원하는 대로
    def update
      Rails.logger.info "RegistrationsController#update - Parameters: #{account_update_params.inspect}"
      self.resource = resource_class.to_adapter.get!(send(:"current_#{resource_name}").to_key)

      if update_resource(resource, account_update_params)
        Rails.logger.info "RegistrationsController#update - SUCCESS: User #{resource.id} updated"
        # ✅ 기본은 notice지만, alert로 띄우고 싶다면 이렇게:
        flash[:alert] = I18n.t("devise.registrations.updated") # 문구는 아래 i18n에서 수정 가능
        # 비밀번호 바뀐 뒤 재로그인 유지
        bypass_sign_in resource, scope: resource_name if sign_in_after_change_password?
        respond_with resource, location: after_update_path_for(resource)
      else
        Rails.logger.info "RegistrationsController#update - FAILED: #{resource.errors.full_messages.join(', ')}"
        clean_up_passwords resource
        set_minimum_password_length
        respond_with resource
      end
    end

    def create
      Rails.logger.info "RegistrationsController#create - Parameters: #{sign_up_params.inspect}"
      build_resource(sign_up_params)
      if resource.name.present? && User.where("LOWER(name) = ?", resource.name.downcase).exists?
        resource.errors.add(:name, :taken)
      end

      if resource.errors.any?
        Rails.logger.info "RegistrationsController#create - Validation errors: #{resource.errors.full_messages.join(', ')}"
        flash.now[:alert] =
          if resource.errors.added?(:name, :taken) && resource.errors.size == 1
            I18n.t("signup.errors.name_taken",
              default: I18n.t("activerecord.errors.models.user.attributes.name.taken",
                              default: "이미 사용 중인 이름입니다."))
          else
            resource.errors.full_messages.join("\n")
          end
        return render :new, status: :unprocessable_entity
      end


      if resource.save
        Rails.logger.info "RegistrationsController#create - SUCCESS: User #{resource.id} created with email #{resource.email}"
        flash[:alert] = I18n.t("devise.registrations.signed_up", default: "회원가입이 완료되었습니다.")
        sign_up(resource_name, resource)
        respond_with resource, location: after_sign_up_path_for(resource)
      else
        Rails.logger.info "RegistrationsController#create - FAILED: #{resource.errors.full_messages.join(', ')}"
        # 이메일 중복만 별도 문구, 그 외는 full_messages
        if resource.errors.added?(:email, :taken)
          flash.now[:alert] = I18n.t("signup.errors.email_taken",
            default: I18n.t("activerecord.errors.models.user.attributes.email.taken",
                            default: "이미 사용 중인 이메일입니다."))
        else
          flash.now[:alert] = resource.errors.full_messages.join("\n")
        end

        render :new, status: :unprocessable_entity
      end
    end
    protected

    # ✅ 리다이렉트 위치 커스텀(원하는 경로로)
    def after_update_path_for(resource)
      root_path
    end

     def after_sign_up_path_for(resource)
    user_path(resource)  # → /users/:id
  end
end

# app/controllers/sessions_controller.rb
class SessionsController < Devise::SessionsController
  respond_to :html, :json, :js

  def create
    scope = :user
    self.resource = warden.authenticate(scope: scope)

    success_msg = I18n.t("devise.sessions.signed_in", default: "성공적으로 로그인했습니다!")
    error_msg   = I18n.t("devise.failure.invalid",    default: "이메일 또는 비밀번호가 올바르지 않습니다.")

    respond_to do |format|
      if resource
        sign_in(scope, resource)

        format.html do
          flash[:alert] = success_msg
          redirect_to root_path, status: :see_other
        end

        format.json do
          # 🔥 로그인 직후 상태 기준으로 부분 뷰를 HTML로 뽑아서 실어 보냄
          nav_html   = render_to_string(partial: "layouts/nav_links", formats: [:html])
          notif_html = render_to_string(partial: "layouts/notification", formats: [:html])

          response.set_header("X-Auth-Result", "success")
          render json: {
            success: true,
            notice:  success_msg,
            signed_in: true,
            nav_html: nav_html,
            notification_html: notif_html,
            redirect_url: after_sign_in_path_for(resource) # 🔥 추가
          }
        end
      else
        format.html do
          flash[:alert] = error_msg
          redirect_to root_path, status: :see_other
        end

        format.json do
          response.set_header("X-Auth-Result", "failure")
          render json: { success: false, errors: [error_msg] }, status: :unauthorized
        end
      end
    end
  end


  # GET /users/sign_in
  def new
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :not_found }
      format.js   { head :not_acceptable }  # prevents UnknownFormat/406
    end
  end

  # DELETE /users/sign_out
  def destroy
    scope = :user
    Devise.sign_out_all_scopes ? sign_out : sign_out(scope)

    respond_to do |format|
      format.html { redirect_to after_sign_out_path_for(scope), status: :see_other }
      format.json { render json: { success: true } }
      format.js   { render json: { success: true } }
    end
  end

  protected

  # ✅ 혹시 다른 경로에서 sign_in이 호출되더라도 루트로
  def after_sign_in_path_for(_resource)
    root_path
  end
end

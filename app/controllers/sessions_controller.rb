# app/controllers/sessions_controller.rb
class SessionsController < Devise::SessionsController
  respond_to :html, :json, :js

  # POST /users/sign_in
# app/controllers/sessions_controller.rb
def create
  scope = :user
  self.resource = warden.authenticate(scope: scope)  # no bang
   success_msg = '성공적으로 로그인했습니다!'
  error_msg = '이메일 또는 비밀번호가 올바르지 않습니다.'

  if resource
    sign_in(scope, resource)
    respond_to do |format|

      format.html { redirect_to after_sign_in_path_for(resource), status: :see_other }
      format.json do
        response.set_header('X-Flash-Notice', success_msg)
        render json: { success: true, notice: success_msg }
      end
      format.js do
        response.set_header('X-Flash-Notice', success_msg)
        render json: { success: true, notice: success_msg }
      end
    end
  else
    respond_to do |format|
      format.html do
        flash.now[:alert] = error_msg
        flash.now[:alert] = '이메일 또는 비밀번호가 올바르지 않습니다.'
        render :new, status: :unauthorized
      end
      format.json { render json: { success: false, errors: ['이메일 또는 비밀번호가 올바르지 않습니다.'] }, status: :unauthorized }
      format.js   { render json: { success: false, errors: ['이메일 또는 비밀번호가 올바르지 않습니다.'] }, status: :unauthorized }
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
      format.html { redirect_to after_sign_out_path_for(scope), status: :see_other, notice: "로그아웃되었습니다." }
      format.json { render json: { success: true } }
      format.js   { render json: { success: true } }
    end
  end
end

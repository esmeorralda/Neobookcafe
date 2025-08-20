# app/controllers/dashboard_controller.rb
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_allowed_email!  # or :ensure_allowed_name!

  def index
    @users = User.select(:id, :name, :email).order(:id)
    @user_count = User.count
    @feedbacks = Feedback.includes(:user).order(created_at: :desc).limit(100)
    @feedbacks_count = Feedback.count
     # ✅ Posts (내용 제외: 본문 칼럼을 안 씀)
    @posts = Post.includes(:user).order(created_at: :desc).limit(100)
    @posts_count = Post.count

    # ✅ Notes (내용 제외)
    @notes = Note.includes(:user).order(created_at: :desc).limit(100)
    @notes_count = Note.count
  end

  private
  def ensure_allowed_email!
    # allowed_name = "여우리"
    # current_name = current_user&.name.to_s.strip

    # unless current_name == allowed_name
    #   redirect_to(root_path, alert: "접근 권한이 없습니다.")
    # end
  end
end

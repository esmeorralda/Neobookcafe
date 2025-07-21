class UsersController < ApplicationController
  def show
  end

  def edit
  end
  
  def new
    @user = User.new
  end

  # def create
  #   @user = User.new(user_params)

  #   if @user.save
  #     session[:user_id] = @user.id
  #     redirect_to root_path, notice: "회원가입이 완료되었습니다."
  #   else
  #     render :new, status: :unprocessable_entity
  #   end
  # end

  # def destroy
  #   @user = User.find(params[:id])
  #   @user.destroy
  #   reset_session
  #   redirect_to root_path, notice: "회원 탈퇴가 완료되었습니다."
  # end

  def my_posts
  @posts = current_user.posts.order(created_at: :desc)
end

def saved_posts
  @posts = current_user.bookmarked_posts.order(created_at: :desc)
end


  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end

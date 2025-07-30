class UsersController < ApplicationController
  def show
  @user = User.find(params[:id])
  per_page = 10

  # 각 카테고리별 1페이지(10개) 초기 로드
 @my_posts = @user.posts.where(draft: false).order(created_at: :desc).page(1).per(per_page)
  @liked_posts = @user.liked_posts.order(created_at: :desc).page(1).per(per_page)
  @saved_posts = @user.bookmarked_posts.order(created_at: :desc).page(1).per(per_page)

  # 탭 기본값: 내가 쓴 글
  @posts = @my_posts

  # 총 페이지 수
  @my_posts_total_pages = @my_posts.total_pages
  @liked_posts_total_pages = @liked_posts.total_pages
  @saved_posts_total_pages = @saved_posts.total_pages
end

  def edit
  end
  
  def new
    @user = User.new
  end

#   def update
#   if current_user.update(user_params)
#     redirect_to user_path(current_user), notice: "수정되었습니다."
#   else
#     render :edit, status: :unprocessable_entity
#   end
# end

def update
  if params[:commit_self_intro]
    # 자기소개만 업데이트
    if current_user.update(user_params)
      redirect_to user_path(current_user), notice: "자기소개가 저장되었습니다."
    else
      flash.now[:alert] = "자기소개 저장에 실패했습니다."
      render :edit
    end

  elsif params[:commit_book_intros]
    # 책 소개만 업데이트
    if params[:book_intros]
      params[:book_intros].each do |_, intro_params|
        if intro_params[:id].present?
          book_intro = current_user.book_intros.find_by(id: intro_params[:id])
          if book_intro
            book_intro.update(
              quote: intro_params[:quote],
              book_title: intro_params[:book_title],
              author_name: intro_params[:author_name]
            )
          end
        else
          # 새로 입력된 경우
          unless intro_params[:quote].blank? && intro_params[:book_title].blank? && intro_params[:author_name].blank?
            current_user.book_intros.create(
              quote: intro_params[:quote],
              book_title: intro_params[:book_title],
              author_name: intro_params[:author_name]
            )
          end
        end
      end
      redirect_to user_path(current_user), notice: "책 소개가 저장되었습니다."
    else
      flash.now[:alert] = "책 소개 저장에 실패했습니다."
      render :edit
    end

  else
    # 기본 처리 (아무 버튼도 안 눌렀을 경우 등)
    redirect_to edit_user_path(current_user)
  end
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
  page = params[:page] || 1
  @posts = current_user.posts.where(draft: [false, nil]).order(created_at: :desc).page(page).per(10)
  @total_pages = @posts.total_pages
  @current_page = @posts.current_page
  render partial: "users/posts_with_pagination", locals: { posts: @posts, page_no: @current_page, total_pages: @total_pages, tab: "my_posts" }
end

def drafted_posts
  page = params[:page] || 1
  @posts = current_user.posts.where(draft: true).order(created_at: :desc).page(page).per(10)
  @total_pages = @posts.total_pages
  @current_page = @posts.current_page
  render partial: "users/posts_with_pagination", locals: { posts: @posts, page_no: @current_page, total_pages: @total_pages, tab: "drafted_posts" }
end

def liked_posts
  page = params[:page] || 1
  @posts = current_user.liked_posts.order(created_at: :desc).page(page).per(10)
  @total_pages = @posts.total_pages
  @current_page = @posts.current_page
  render partial: "users/posts_with_pagination", locals: { posts: @posts, page_no: @current_page, total_pages: @total_pages, tab: "liked_posts" }
end

def saved_posts
  page = params[:page] || 1
  @posts = current_user.bookmarked_posts.order(created_at: :desc).page(page).per(10)
  @total_pages = @posts.total_pages
  @current_page = @posts.current_page
  render partial: "users/posts_with_pagination", locals: { posts: @posts, page_no: @current_page, total_pages: @total_pages, tab: "saved_posts" }
end


  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :self_intro, :name)
  end
end

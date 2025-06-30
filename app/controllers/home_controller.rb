class HomeController < ApplicationController
  def index
    @posts = Post.order(created_at: :desc).limit(20)  # 예: 최신 20개 글 가져오기
  end
end

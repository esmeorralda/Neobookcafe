# app/controllers/posts_controller.rb
class PostsController < ApplicationController
    before_action :authenticate_user!, only: [:new, :create]
    def new
      @post = Post.new
      3.times { @post.post_blocks.build } # 기본 3개 블록 생성
    end
  
    def create
        @post = Post.new(post_params)
        @post.user = current_user 
        if @post.save
          redirect_to @post, notice: "포스트가 저장되었습니다."
        else
          logger.debug @post.errors.full_messages
          render :new, status: :unprocessable_entity
        end
      end
      
    def show
      @post = Post.find(params[:id])
    end

    def index
      if params[:category].present?
        @posts = Post.where(category: params[:category])
      else
        @posts = Post.all
      end

      case params[:sort]
      when "popular"
        # 좋아요 수 내림차순 (또는 조회수 등으로 변경 가능)
        @posts = @posts.order(like_count: :desc)
      when "latest"
        @posts = @posts.order(created_at: :desc)

      else
        @posts = @posts.order(created_at: :desc) # 기본 최신순
      end
    end
  
    private
  
    def post_params
      params.require(:post).permit(
        :title, :author, :book_title, :book_author, :book_genre, :category,
        :save_count, :like_count, :view_count,
        post_blocks_attributes: [:id, :block_type, :content, :position, :_destroy]
      )
    end
    
 
  end
  
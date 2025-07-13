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
  sorted_posts = fetch_cached_posts

  @posts = case params[:sort]
           when "popular"
             sorted_posts.sort_by { |p| -p.like_count }
           else
             sorted_posts
           end

  total_count = @posts.size
  @total_pages = (total_count / per_page.to_f).ceil

  # paginate는 Relation용이라 Array일 경우에는 직접 자르기
  if @posts.is_a?(Array)
    @posts = @posts.slice((page_no - 1) * per_page, per_page) || []
  else
    @posts = paginate.call(@posts)
  end

  Rails.logger.debug "page_no: #{page_no}, per_page: #{per_page}, total_pages: #{@total_pages}" 

  Rails.logger.debug "book_genre: #{params[:book_genre]}, category: #{
params[:category]}"


end

    private

def fetch_cached_posts
    category = params[:category].presence || "all"
    book_genre    = params[:book_genre].presence || "all"

    cache_key = "posts/#{category}/#{book_genre}"

    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      scope = Post.all
      scope = scope.where(category: category) unless category == "all"
      scope = scope.where(book_genre: book_genre) unless book_genre == "all"
      scope.order(created_at: :desc).to_a
    end
  end

    def post_params
      params.require(:post).permit(
        :title, :author, :book_title, :book_author, :book_genre, :category,
        :save_count, :like_count, :view_count,
        post_blocks_attributes: [:id, :block_type, :content, :position, :_destroy]
      )
    end
    
 
  end
  
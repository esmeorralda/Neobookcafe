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
    @posts = if params[:category].present?
               Post.where(category: params[:category])
             else
               Post.all
             end

    @posts = case params[:sort]
             when "popular"
               @posts.order(like_count: :desc)
             when "latest"
               @posts.order(created_at: :desc)
             else
               @posts.order(created_at: :desc)
             end

     @posts = paginate.call(@posts)

    total_count = if params[:category].present?
                Post.where(category: params[:category]).count
              else
                Post.count
              end
@total_pages = (total_count / per_page.to_f).ceil


    Rails.logger.debug "page_no: #{page_no}, per_page: #{per_page}, total_pages: #{@total_pages}"
  end
def test_helper
  render plain: "page_no is #{page_no}"
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
  
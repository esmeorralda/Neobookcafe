# app/controllers/posts_controller.rb
class PostsController < ApplicationController
    before_action :authenticate_user!, only: [:new, :create, :bookmark, :unbookmark]
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

  session[:viewed_posts] ||= []
  @comments = @post.comments.includes(:user)

  unless session[:viewed_posts].include?(@post.id)
    @post.increment!(:view_count)
    session[:viewed_posts] << @post.id
  end
end


def index
     @show_sidebar = true
  sorted_posts = fetch_cached_posts

  @posts = case params[:sort]
           when "popular"
             sorted_posts.sort_by { |p| -p.like_count.to_i }
           when "most_comments"
             sorted_posts.sort_by { |p| -total_comments_count(p)}
           when "most_views"
           sorted_posts.sort_by { |p| -p.view_count.to_i }
         when "newest"
           sorted_posts.sort_by { |p| -p.created_at.to_i }
         when "most_likes"
           sorted_posts.sort_by { |p| -p.like_count.to_i }
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

# def search
#   @query = params[:q].to_s.strip.downcase
#   return redirect_to root_path if @query.blank?

#   base_query = Post.includes(:user, :post_blocks)
#                   .joins(:user, :post_blocks)
#                   .distinct
#                   .where(
#                     "LOWER(posts.title) LIKE :q OR 
#                      LOWER(posts.book_title) LIKE :q OR 
#                      LOWER(posts.book_author) LIKE :q OR 
#                      LOWER(users.name) LIKE :q OR 
#                      LOWER(post_blocks.content) LIKE :q",
#                     q: "%#{@query}%"
#                   )

#   @posts = apply_sorting(base_query)
#   @total_count = @posts.size
#   @posts = Kaminari.paginate_array(@posts).page(params[:page]).per(20)
  
#   # Changed to render search template
#   render 'search'
# end

def search
   @is_search_result = true
  @query = params[:q].to_s.strip
  return redirect_to root_path if @query.blank?

  base_scope = Post.pg_search(@query)
                   .includes(:user, :post_blocks) # 여기 포함!

   # category 필터
  if params[:category].present?
    base_scope = base_scope.where(category: params[:category])
  end

  # genre 필터
  if params[:genre].present?
    base_scope = base_scope.where(book_genre: params[:genre])
  end

@posts = case params[:sort]
         when "most_views"
           base_scope.reorder(view_count: :desc)
         when "most_likes"
           base_scope.reorder(like_count: :desc)
         when "newest"
           base_scope.reorder(created_at: :desc)
         when "relevance"
           base_scope.order("rank DESC")
         else
           base_scope.order("rank DESC") # 기본은 관련도순
         end

  @posts = @posts.page(params[:page]).per(20)
  @total_pages = @posts.total_pages
  render 'search'
end



def bookmark
  @post = Post.find(params[:post_id])
  current_user.bookmarks.create(post: @post)
  redirect_back(fallback_location: post_path(@post), notice: '게시글을 북마크했습니다.')
end

def unbookmark
  @post = Post.find(params[:post_id])
  bookmark = current_user.bookmarks.find_by(post: @post)
  bookmark&.destroy
  redirect_back(fallback_location: post_path(@post), notice: '북마크를 취소했습니다.')
end

private

def apply_sorting(scope)
  case params[:sort]
when "most_comments"
  scope.left_joins(:comments)
       .group("posts.id")
       .order("COUNT(comments.id) DESC")
  when "most_views"
    scope.order(view_count: :desc)
  when "most_likes"
    scope.order(like_count: :desc)
  else # 기본은 최신순
    scope.order(created_at: :desc)
  end
end


def calculate_relevance(post)
  score = 0
  query = params[:q].to_s.downcase
  
  score += 3 if post.title&.downcase&.include?(query)
  score += 2 if post.book_title&.downcase&.include?(query)
  score += 2 if post.book_author&.downcase&.include?(query)
  score += 1 if post.user&.name&.downcase&.include?(query)
  score += 1 if post.post_blocks.any? { |block| block.content&.downcase&.include?(query) }
  
  score
end


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

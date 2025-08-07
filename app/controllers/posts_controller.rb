# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :authenticate_user!, except: [:show, :index, :search]

    def new
      @post = Post.new

    end
  def create
  @post = current_user.posts.new(post_params)

  if params[:commit] == "draft"
    @post.draft = true
    if @post.save
      redirect_to root_path, notice: "임시 저장 완료"
    else
      render :new, status: :unprocessable_entity
    end
    return
  end

  @post.draft = false
  full_text = @post.title.to_s + " " + @post.post_blocks.map(&:content).join(" ")
  flagged_results = KorcenFilterService.analyze_text(full_text)

  if flagged_results.any?
     @post.contains_profanity = true  # ✅ 반드시 명시적으로 설정!

    alert_messages = flagged_results.map do |result|
      sentence = clean_sentence(result[:sentence])
      categories = result[:categories]
                      .select { |_, v| v }      
                      .keys
                      .map { |cat| korean_reason_map(cat.to_s) } 
                      .join(", ")
      "문장: #{sentence}\n\n감지된 비속어 유형: #{categories}"
    end.join("\n\n")

    @alert_messages = "비속어가 포함된 문장이 감지되었습니다:\n\n" + alert_messages + "\n\n이는 청소년 보호 정책의 일환으로 제한됩니다. 문장을 수정하여 다시 업로드해 주세요."

render :new, status: :unprocessable_entity, locals: { post: @post }

    return
  else

end

 if @post.save
  Rails.logger.debug "✅ 저장 성공: contains_profanity == false && post.save 성공"
  Rails.logger.debug "post 상태: #{@post.inspect}"
  redirect_to @post, notice: "게시글이 등록되었습니다."
else
 error_map = {
  "Title can't be blank" => "글 제목을 입력하세요.",
  "Book title can't be blank" => "책 제목을 입력하세요.",
  "Book author can't be blank" => "책 저자를 입력하세요.",
  "Category can't be blank" => "카테고리를 선택하세요.",
  "Book genre can't be blank" => "장르를 선택하세요."
}

    # 전체 에러 메시지 한글 변환
    translated_messages = @post.errors.full_messages.map do |msg|
      error_map[msg] || msg
    end

    @alert_messages = translated_messages.join("\n")

  render :new, status: :unprocessable_entity
end

end

  def show

  @post = Post.find(params[:id])

  session[:viewed_posts] ||= []
  @comments = @post.comments.where(parent_id: nil, post_block_id: nil).reorder(created_at: :desc)
Rails.logger.debug "@comments order: #{@comments.pluck(:created_at)}"

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
                   .where("draft = ? OR draft IS NULL", false)

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

def update
  @post = Post.find(params[:id])

  Post.transaction do
    # 기존 블럭들 삭제
    @post.post_blocks.destroy_all

    if @post.update(post_params)
      redirect_to @post, notice: "게시글이 성공적으로 수정되었습니다."
    else
      raise ActiveRecord::Rollback
    end
  end

rescue
  flash.now[:alert] = "수정에 실패했습니다."
  render :edit
end


    def edit
  @post = Post.find(params[:id])
  # @post는 DB에 저장된 값들이 채워진 상태
end

    
def destroy
  @post = Post.find(params[:id])
  if @post.user != current_user
    redirect_to posts_path, alert: "권한이 없습니다." and return
  end

  @post.destroy
  redirect_to posts_path, notice: "게시글이 삭제되었습니다."
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

def korean_reason_map(category)
  case category
  when "general" then "일반 비속어"
  when "minor" then "경미한 비속어"
  when "sexual" then "성적 비속어"
  when "belittle" then "모욕적 표현"
  when "race" then "인종차별적 표현"
  when "parents" then "가족 비하"
  when "foreign" then "외국인 비하"
  when "special" then "특수 비속어"
  when "politics" then "정치적 비속어"
  else category
  end
end

def clean_sentence(text)
  text.gsub(/[\r\n\t]+/, " ")  # 줄바꿈과 탭을 공백으로 변환
      .gsub(/[\d,]+/, "")      # 숫자와 쉼표 제거
      .strip                   # 앞뒤 공백 제거
end



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

 def total_comments_count(post)
    Comment.where(post_id: post.id).count
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

    cache_key = "posts/#{category}/#{book_genre}/published"

    Rails.cache.fetch(cache_key, expires_in: 10.minutes) do
      scope = Post.where(draft: false).or(Post.where(draft: nil))
      scope = scope.where(category: category) unless category == "all"
      scope = scope.where(book_genre: book_genre) unless book_genre == "all"
      scope.order(created_at: :desc).to_a
    end
  end

    def post_params
      params.require(:post).permit(
        :title, :author, :book_title, :book_author, :book_genre, :category,
        :save_count, :like_count, :view_count, genres: [], 
        post_blocks_attributes: [:id, :block_type, :content, :position, :_destroy]
      )
    end
    
 
  end

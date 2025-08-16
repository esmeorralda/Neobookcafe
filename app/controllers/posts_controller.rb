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

    messages = flagged_results.map do |result|
      sentence = clean_sentence(result[:sentence])
      categories = result[:categories]
                      .select { |_, v| v }      
                      .keys
                      .map { |cat| korean_reason_map(cat.to_s) } 
                      .join(", ")
      "문장: #{sentence}\n\n감지된 비속어 유형: #{categories}"
    end.join("\n\n")

  final_messages = "비속어가 포함된 문장이 감지되었습니다:\n\n" + messages + "\n\n이는 청소년 보호 정책의 일환으로 제한됩니다. 문장을 수정하여 다시 업로드해 주세요."
    flash.now[:alert] = final_messages

render :new, status: :unprocessable_entity, locals: { post: @post }

    return
  else

end
if (flagged = ModerationChecker.check(full_text))
  translations = moderation_category_translations
  # flagged가 [["harassment", 0.12], ["violence", 0.15]] 같은 배열이라고 가정
  categories_with_scores = flagged.is_a?(Array) && flagged.first.is_a?(Array) ? flagged : [flagged]

  messages = categories_with_scores.map do |category, score|
    "#{translations[category]} (#{(score.to_f * 100).round(1)}%)"
  end.compact

  flash.now[:alert] = "⚠️ 다음과 같은 유해 콘텐츠가 포함되어 있습니다: #{messages.join(', ')}. 수정 후 다시 시도해 주세요."
  return render :new, status: :unprocessable_entity, locals: { post: @post }
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

    sort       = params[:sort].presence || "newest"
    page       = page_no
    per        = per_page
    category   = params[:category].presence
    book_genre = book_genre_param
    version    = cache_version_for(sort)

    ids_key   = "posts:index:ids:cat=#{category || 'all'}:genre=#{book_genre || 'all'}:sort=#{sort}:v=#{version}:page=#{page}:per=#{per}"
    count_key = "posts:index:count:cat=#{category || 'all'}:genre=#{book_genre || 'all'}:sort=#{sort}:v=#{version}"

    # ---- Base scope (draft 제외) + 필터 ----
    scope = Post.where(draft: [false, nil])
    scope = scope.where(category: category)     if category
    scope = scope.where(book_genre: book_genre) if book_genre

    # ---- 정렬은 DB가 처리 ----
    relation = relation_for_sort(scope, sort)

    # ---- 전체 개수 캐시 (GROUP BY 부작용 피하려면 except(:order)) ----
    total_count = Rails.cache.fetch(count_key, expires_in: ttl_for(sort)) do
      if %w[most_likes popular most_comments].include?(sort)
        scope.count
      else
        relation.except(:order).count
      end
    end
    @total_pages = (total_count / per.to_f).ceil

    # ---- 페이지별 ID 캐시 ----
    ids = Rails.cache.fetch(ids_key, expires_in: ttl_for(sort)) do
      offset = (page - 1) * per
      relation.limit(per).offset(offset).pluck(Arel.sql("posts.id"))
    end

    # ---- 하이드레이션 (원래 순서 유지) ----
    posts_by_id = Post.where(id: ids).includes(:user, :post_blocks).index_by(&:id)
    @posts = ids.map { |id| posts_by_id[id] }.compact

    # ---- 장르 탭 표시 규칙 (이전 로직과 동일) ----
    if category.present?
      @show_genre_tap = category != "board"
    else
      @show_genre_tap = !@posts.all? { |p| p.respond_to?(:category) && p.category == "board" }
    end

    Rails.logger.debug "page_no: #{page}, per_page: #{per}, total_pages: #{@total_pages}"
    Rails.logger.debug "category: #{category}, book_genre: #{book_genre}, sort: #{sort}"
  end

  

def search
  @is_search_result = true
  @query = params[:q].to_s.strip
  return redirect_to root_path if @query.blank?

  base = Post.pg_search(@query)              # pg_search 스코프
             .with_pg_search_rank            # pg_search_rank 노출
             .where(draft: [false, nil])
             .preload(:user, :first_block)   # JOIN 방지, 필요한 것만
             .select("posts.*")              # (선택) 필요 컬럼만 select 로 좁힐 수 있음

  base = base.where(category:   params[:category])   if params[:category].present?
  base = base.where(book_genre: params[:genre])      if params[:genre].present?

  @posts =
    case params[:sort]
    when "most_views"
      base.reorder(Arel.sql("COALESCE(posts.view_count,0) DESC"))
          .order(pg_search_rank: :desc, created_at: :desc)
    when "most_likes"
      base.reorder(Arel.sql("COALESCE(posts.like_count,0) DESC"))
          .order(pg_search_rank: :desc, created_at: :desc)
    when "newest"
      base.reorder(created_at: :desc)
          .order(pg_search_rank: :desc)
    when "relevance", nil, ""
      base.order(pg_search_rank: :desc, created_at: :desc)
    else
      base.order(pg_search_rank: :desc, created_at: :desc)
    end

  @posts = @posts.page(params[:page]).per(20)
  @total_pages = @posts.total_pages
  render "search"
end

def update


  @post = Post.find(params[:id])

  # 사용자가 입력한 값을 미리 @post에 반영 (렌더할 때 필요)
  @post.assign_attributes(post_params)

  # 블록들 내용 추출
  title = @post.title.to_s
  blocks = @post.post_blocks || []
  block_contents = blocks.map(&:content).compact.join(" ")
  full_text = title + " " + block_contents

  # Korcen 모더레이션
  flagged_results = KorcenFilterService.analyze_text(full_text)

  if flagged_results.any?
    messages = flagged_results.map do |result|
      sentence = clean_sentence(result[:sentence])
      categories = result[:categories]
                      .select { |_, v| v }
                      .keys
                      .map { |cat| korean_reason_map(cat.to_s) }
                      .join(", ")
      "문장: #{sentence}\n\n감지된 비속어 유형: #{categories}"
    end.join("\n\n")

    final_messages = "비속어가 포함된 문장이 감지되었습니다:\n\n" + messages +
                     "\n\n이는 청소년 보호 정책의 일환으로 제한됩니다. 문장을 수정하여 다시 업로드해 주세요."
    flash.now[:alert] = final_messages
        @suppress_post_blocks_rendering = true 
         @edited_post_blocks = (post_params[:post_blocks_attributes]&.values || []).map do |block_params|
  PostBlock.new(block_type: block_params[:block_type], content: block_params[:content])
end

         Rails.logger.debug "===== @edited_post_blocks 내용 ====="
Rails.logger.debug @edited_post_blocks.inspect
Rails.logger.debug "================================="
    return render :edit, status: :unprocessable_entity, locals: { post: @post }
  end

  # Moderation API
  if (flagged = ModerationChecker.check(full_text))
    translations = moderation_category_translations
    categories_with_scores = flagged.is_a?(Array) && flagged.first.is_a?(Array) ? flagged : [flagged]

    messages = categories_with_scores.map do |category, score|
      "#{translations[category]} (#{(score.to_f * 100).round(1)}%)"
    end.compact

    flash.now[:alert] = "⚠️ 다음과 같은 유해 콘텐츠가 포함되어 있습니다: #{messages.join(', ')}. 수정 후 다시 시도해 주세요."
        @suppress_post_blocks_rendering = true 
      @edited_post_blocks = (post_params[:post_blocks_attributes]&.values || []).map do |block_params|
  PostBlock.new(block_type: block_params[:block_type], content: block_params[:content])
end

    return render :edit, status: :unprocessable_entity, locals: { post: @post }
  end

  # 정상 업데이트
  Post.transaction do
    @post.post_blocks.destroy_all
    if @post.update(post_params)
      redirect_to @post, notice: "게시글이 성공적으로 수정되었습니다."
    else
      raise ActiveRecord::Rollback
    end
  end
rescue
  flash.now[:alert] = "수정에 실패했습니다."
  render :edit, locals: { post: @post }
end

    def edit
       @suppress_post_blocks_rendering = true 
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

def relation_for_sort(scope, sort)
  case sort
  when "newest"
    scope.order(created_at: :desc)

  when "most_views"
    scope.order(Arel.sql("COALESCE(posts.view_count, 0) DESC, posts.created_at DESC"))

  when "most_likes", "popular"
    scope.left_joins(:likes)
         .group("posts.id")
         .order(Arel.sql("COUNT(likes.id) DESC, posts.created_at DESC"))

  when "most_comments"
    scope.left_joins(:comments)
         .group("posts.id")
         .order(Arel.sql("COUNT(comments.id) DESC, posts.created_at DESC"))

  else
    scope.order(created_at: :desc)
  end
end


  # ---- Cache version seed (bumps when relevant data changes) ----
  def cache_version_for(sort)
    base = Post.where(draft: [false, nil]).maximum(:updated_at)&.to_i || 0
    case sort
    when "most_likes", "popular"
      [base, Like.maximum(:updated_at)&.to_i || 0].max
    when "most_comments"
      [base, Comment.maximum(:updated_at)&.to_i || 0].max
    when "most_views"
      base
    else
      base
    end
  end

  # ---- TTL by sort ----
  def ttl_for(sort)
    case sort
    when "most_views"                then 1.minute
    when "most_likes", "popular",
         "most_comments"             then 5.minutes
    else                                 3.minutes
    end
  end

  # ---- Pagination helpers ----
  def per_page
    (params[:per_page].presence || 20).to_i.clamp(1, 100)
  end

  def page_no
    (params[:page].presence || 1).to_i.clamp(1, 100_000)
  end

  # Accept both ?book_genre= and ?genre=
  def book_genre_param
    params[:book_genre].presence || params[:genre].presence
  end


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

def moderation_category_translations
  {
    "sexual" => "성적 내용",
    "hate" => "증오 발언",
    "harassment" => "괴롭힘",
    "self-harm" => "자해",
    "sexual/minors" => "아동 성적 내용",
    "hate/threatening" => "위협적인 증오 발언",
    "violence/graphic" => "노골적인 폭력",
    "self-harm/intent" => "자해 의도",
    "self-harm/instructions" => "자해 방법 안내",
    "harassment/threatening" => "위협적인 괴롭힘",
    "violence" => "폭력"
  }
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

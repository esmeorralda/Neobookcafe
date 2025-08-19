class HomeController < ApplicationController
def index
  @show_sidebar = true
  @show_genre_tap = true

  sort = params[:sort].presence || "newest"
  page = page_no
  per  = per_page

  scope    = Post.where(draft: [false, nil])
  relation = relation_for_sort(scope, sort)

  # ✅ params를 바로 써서 undefined 방지
  count_key = CacheKeyHelper.vposts_key(
    "home:index:count",
    sort: sort, category: params[:category], book_genre: params[:book_genre]
  )

  ids_key = CacheKeyHelper.vposts_key(
    "home:index:ids",
    sort: sort, category: params[:category], book_genre: params[:book_genre], page: page, per: per
  )

  # 총 개수 캐시
  total_count = Rails.cache.fetch(count_key, expires_in: ttl_for(sort)) do
    if %w[most_likes popular most_comments].include?(sort)
      scope.count
    else
      relation.except(:order).count
    end
  end
  @total_pages = (total_count / per.to_f).ceil

  # 해당 페이지의 ID 목록 캐시
  ids = Rails.cache.fetch(ids_key, expires_in: ttl_for(sort)) do
    offset = (page - 1) * per
    relation.limit(per).offset(offset).reselect("posts.id").pluck(:id)
  end

  # ID 순서대로 객체 하이드레이트
  posts_by_id = Post.where(id: ids).index_by(&:id)
  @posts = ids.map { |id| posts_by_id[id] }.compact
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
    base = Post.where(draft: [ false, nil ]).maximum(:updated_at)&.to_i || 0
    case sort
    when "most_likes", "popular"
      [ base, Like.maximum(:updated_at)&.to_i || 0 ].max
    when "most_comments"
      [ base, Comment.maximum(:updated_at)&.to_i || 0 ].max
    when "most_views"
      # If you frequently update view_count in-place, base is enough; adjust if you track view events separately.
      base
    else
      base
    end
  end

  # ---- TTL by sort (tune to your traffic pattern) ----
  def ttl_for(sort)
    case sort
    when "most_views"          then 1.minute
    when "most_likes", "popular",
         "most_comments"       then 5.minutes
    else                           3.minutes
    end
  end

  # ---- Pagination helpers ----
  def per_page
    (params[:per_page].presence || 20).to_i.clamp(1, 100)
  end

  def page_no
    (params[:page].presence || 1).to_i.clamp(1, 100_000)
  end

  # (Still available if you need it elsewhere)
  def total_comments_count(post)
    Comment.where(post_id: post.id).count
  end
end

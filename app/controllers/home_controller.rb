class HomeController < ApplicationController
  def index
    @show_sidebar = true

    sort     = params[:sort].presence || "newest"
    page     = page_no
    per      = per_page
    version  = cache_version_for(sort)
    ids_key  = "home:index:ids:sort=#{sort}:v=#{version}:page=#{page}:per=#{per}"
    count_key= "home:index:count:sort=#{sort}:v=#{version}"

    # Build the relation for this sort (no includes/preload here; we’ll hydrate after)
    scope    = Post.where(draft: [false, nil])
    relation = relation_for_sort(scope, sort)

    # Cache the count (avoid GROUP BY side effects)
    total_count = Rails.cache.fetch(count_key, expires_in: ttl_for(sort)) do
      if %w[most_likes popular most_comments].include?(sort)
        scope.count # base scope count
      else
        relation.except(:order).count
      end
    end

    @total_pages = (total_count / per.to_f).ceil

    # Cache the page’s ordered IDs
    ids = Rails.cache.fetch(ids_key, expires_in: ttl_for(sort)) do
      offset = (page - 1) * per
      # Make sure we pluck explicit posts.id in case the relation has custom SELECTs
      relation.limit(per).offset(offset).pluck(Arel.sql("posts.id"))
    end

    # Hydrate and preserve order
    posts_by_id = Post.where(id: ids).includes(:user, :post_blocks).index_by(&:id)
    @posts = ids.map { |id| posts_by_id[id] }.compact
  end

  private

  # ---- Sorting relations (SQL-accurate) ----
  def relation_for_sort(scope, sort)
    case sort
    when "newest"
      scope.order(created_at: :desc)

    when "most_views"
      scope.order(Arel.sql("COALESCE(posts.view_count, 0) DESC, posts.created_at DESC"))

    when "most_likes", "popular"
      scope.left_joins(:likes)
           .select("posts.*, COUNT(likes.id) AS likes_count")
           .group("posts.id")
           .order(Arel.sql("likes_count DESC, posts.created_at DESC"))

    when "most_comments"
      scope.left_joins(:comments)
           .select("posts.*, COUNT(comments.id) AS comments_count")
           .group("posts.id")
           .order(Arel.sql("comments_count DESC, posts.created_at DESC"))

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

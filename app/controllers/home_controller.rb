class HomeController < ApplicationController

  
  def index
    # Start with a base query
    base_query = Post.includes(:user, :comments, :post_blocks)

    # Apply sorting
    @posts = case params[:sort]
             when "newest"
               base_query.order(created_at: :desc)
             when "most_comments"
               base_query.select('posts.*, COUNT(comments.id) as comments_count')
                        .left_joins(:comments)
                        .group('posts.id')
                        .order('comments_count DESC')
             when "most_views"
               base_query.order(view_count: :desc)
             when "most_likes"
               base_query.order(like_count: :desc)
             else
               base_query.order(created_at: :desc)
             end

    # Get total count for pagination
    total_count = @posts.except(:group, :select).count # Remove group clause for count
    @total_pages = (total_count / per_page.to_f).ceil

    # Apply pagination
    @posts = @posts.limit(per_page).offset((page_no - 1) * per_page)
  end
end

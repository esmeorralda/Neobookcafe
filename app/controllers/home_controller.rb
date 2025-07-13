class HomeController < ApplicationController

  
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
end

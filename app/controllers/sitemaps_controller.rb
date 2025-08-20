# app/controllers/sitemaps_controller.rb
class SitemapsController < ApplicationController
  layout false

  def index
    @static_urls = [root_url]
    @posts = Post.order(updated_at: :desc).limit(5000) # 필요에 맞게
  end
end

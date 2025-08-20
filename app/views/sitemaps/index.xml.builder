# app/views/sitemaps/index.xml.builder
xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset "xmlns" => "http://www.sitemaps.org/schemas/sitemap/0.9" do
  @static_urls.each do |u|
    xml.url do
      xml.loc u
      xml.changefreq "daily"
      xml.priority "1.0"
    end
  end

  @posts.each do |post|
    xml.url do
      xml.loc post_url(post)
      xml.lastmod post.updated_at.strftime("%Y-%m-%d")
      xml.changefreq "weekly"
      xml.priority "0.6"
    end
  end
end

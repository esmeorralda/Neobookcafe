# app/views/posts/feed.rss.builder
xml.instruct! :xml, version: "1.0"
xml.rss version: "2.0" do
  xml.channel do
    xml.title       "네오북카페 최신 글"
    xml.link        root_url
    xml.description "독서 토론·기록 최신 포스트"
    @posts.each do |post|
      xml.item do
        xml.title       post.title
        xml.link        post_url(post)
        xml.guid        post_url(post)
        xml.pubDate     post.created_at.to_s(:rfc822)
        xml.description truncate(strip_tags(post.try(:content).to_s), length: 200)
      end
    end
  end
end

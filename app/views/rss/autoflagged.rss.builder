xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0" do
  xml.channel do
    xml.title "Autoflagged Posts"
    xml.description "Posts which have been autoflagged by Charcoal HQ"
    xml.link root_url

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.body
        xml.pubDate post.created_at.to_s(:rfc822)
        xml.link url_for(controller: 'posts', action: 'show', id: post.id)
        xml.link url_for(controller: 'posts', action: 'show', id: post.id)
      end
    end
  end
end
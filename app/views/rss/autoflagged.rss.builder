# frozen_string_literal: true

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'Autoflagged Posts'
    xml.description 'Posts which have been autoflagged by Charcoal HQ'
    xml.link root_url
    # category
    xml.copyright 'Copyright 2018 CharcoalHQ'
    # docs
    xml.language 'en-us'
    xml.lastBuildDate DateTime.now.strftime('%a, %-d %b %Y %T %z')
    xml.managingEditor 'admin@charcoalhq.org'
    xml.pubDate DateTime.now.strftime('%a, %-d %b %Y %T %z')
    xml.webMaster 'webmaster@charcoalhq.org'
    xml.generator 'Ruby on Rails XML generator'

    xml.image do
      xml.url 'https://charcoal-se.org/assets/images/charcoal.png'
      xml.title 'Autoflagged Posts'
      xml.link root_url
      xml.description 'Posts which have been autoflagged by Charcoal HQ'
      xml.width 516
      xml.height 516
    end

    @posts.each do |post|
      xml.item do
        xml.title post.title
        xml.description post.body
        xml.link url_for(controller: 'posts', action: 'show', id: post.id, only_path: false)
        # category
        # comments
        xml.pubDate post.created_at.strftime('%a, %-d %b %Y %T %z')
      end
    end
  end
end

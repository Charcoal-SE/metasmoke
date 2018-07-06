# frozen_string_literal: true

xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'CharcoalHQ'
    xml.description 'Posts which have been caught by Charcoal HQ'
    xml.link root_url
    # category
    xml.copyright 'Copyright 2018 CharcoalHQ'
    # docs
    xml.language 'en-us'
    xml.lastBuildDate DateTime.now.strftime('%a, %-d %b %Y %T %z')
    xml.managingEditor 'smokey@charcoal-se.org'
    xml.pubDate DateTime.now.strftime('%a, %-d %b %Y %T %z')
    xml.webMaster 'smokey@charcoal-se.org'
    xml.generator 'Ruby on Rails XML generator'

    xml.image do
      xml.url 'https://charcoal-se.org/assets/images/charcoal.png'
      xml.title 'CharcoalHQ'
      xml.link root_url
      xml.description 'Posts which have been caught by Charcoal HQ'
      xml.width 516
      xml.height 516
    end

    @posts.each do |post|
      xml.item do
        tags = []
        tags.push 'deleted' unless post.deleted_at.nil?
        tags.push 'autoflagged' if post.autoflagged
        xml.title "[#{tags.join('] [')}] #{post.title}"
        if params[:prefix_user] == 'true'
          xml.description "#{link_to post.stack_exchange_user.username, post.stack_exchange_user.stack_link} #{post.body}"
        else
          xml.description post.body
        end
        case params[:link_type].to_s.downcase
        when 'user'
          xml.link post.stack_exchange_user.stack_link
        when 'onsite'
          xml.link post.link
        else
          xml.link url_for(controller: 'posts', action: 'show', id: post.id, only_path: false)
        end
        # category
        # comments
        xml.pubDate post.created_at.strftime('%a, %-d %b %Y %T %z')
      end
    end
  end
end

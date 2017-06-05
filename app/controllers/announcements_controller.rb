# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  before_action :verify_core

  @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)

  def new
    @announcement = Announcement.new
  end

  def create
    html = @markdown_renderer.render(params[:text])
    date = Date.parse(params[:expiry_date])
    time = Time.parse(params[:expiry_time])
    expiry = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone)

    @announcement = Announcement.new(text: html, expiry: expiry)
    if @announcement.save
      flash[:success] = 'Created your announcement.'
      redirect_to url_for(controller: :announcements, action: :new)
    else
      flash[:error] = "Couldn't create your announcement."
      render :new, status: 500
    end
  end
end

class AnnouncementScrubber < Rails::Html::PermitScrubber
  def initialize
    super
    self.tags = %w[a p b i em strong hr h1 h2 h3 h4 h5 h6 blockquote img strike del code pre br ul ol li]
    self.attributes = %w[href title src height width]
  end

  def skip_node?(node)
    node.text?
  end
end

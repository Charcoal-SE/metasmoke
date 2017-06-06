# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  before_action :verify_core

  @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)

  def self.renderer
    @markdown_renderer
  end

  def new
    @announcement = Announcement.new
  end

  def create
    html = self.class.renderer.render(params[:text])
    date = Date.parse(params[:expiry_date])
    time = Time.parse(params[:expiry_time])
    expiry = DateTime.new(date.year, date.month, date.day, time.hour, time.min, time.sec, time.zone)

    @announcement = Announcement.new(text: html, expiry: expiry)
    if @announcement.save
      flash[:success] = 'Created your announcement.'
      AnnouncementsMailer.announce(@announcement).deliver_now
      redirect_to url_for(controller: :announcements, action: :new)
    else
      flash[:error] = "Couldn't create your announcement."
      render :new, status: 500
    end
  end
end

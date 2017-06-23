# frozen_string_literal: true

class AnnouncementsController < ApplicationController
  before_action :verify_core
  before_action :verify_admin, only: [:expire]

  @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)

  def self.renderer
    @markdown_renderer
  end

  def index
    @announcements = Announcement.all.sort_by(&:created_at).reverse
  end

  def expire
    @announcement = Announcement.find(params[:id])

    if @announcement.update(expiry: DateTime.now)
      flash[:success] = 'Announcement expired'
    else
      flash[:danger] = 'Something went wrong'
    end

    redirect_to announcements_path
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

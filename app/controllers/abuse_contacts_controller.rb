# frozen_string_literal: true

class AbuseContactsController < ApplicationController
  before_action :verify_core, except: [:index, :show]
  before_action :set_contact, except: [:index, :create]
  before_action :verify_admin, only: [:destroy]

  @markdown_renderer = Redcarpet::Markdown.new(Redcarpet::Render::HTML.new)

  def self.renderer
    @markdown_renderer
  end

  def index
    @contacts = AbuseContact.all.order(:name).paginate(page: params[:page], per_page: 100)
  end

  def create
    @contact = AbuseContact.new contact_params
    if @contact.save
      flash[:success] = 'Created contact.'
      flash[:abuse_contact_id] = @contact.id
      redirect_back fallback_location: abuse_contact_path(@contact)
    else
      flash[:danger] = 'Failed to create contact.'
      redirect_back fallback_location: abuse_contacts_path
    end
  end

  def show
    @reports = @contact.reports.includes(:status, :contact, :user)
  end

  def edit; end

  def update
    if @contact.update contact_params
      flash[:success] = 'Contact updated.'
      redirect_to abuse_contact_path(@contact)
    else
      flash[:danger] = 'Failed to update contact.'
      render :edit
    end
  end

  def destroy
    if @contact.destroy
      flash[:success] = 'Removed contact.'
      redirect_to abuse_contacts_path
    else
      flash[:danger] = 'Failed to remove contct.'
      redirect_to abuse_contact_path(@contact)
    end
  end

  private

  def set_contact
    @contact = AbuseContact.find params[:id]
  end

  def contact_params
    params.require(:abuse_contact).permit(:name, :email, :link, :details)
  end
end

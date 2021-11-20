# frozen_string_literal: true

class Emails::PreferencesController < ApplicationController
  before_action :set_preference, except: %i[list search]
  before_action :verify_permissions, except: %i[list search]
  before_action :verify_admin, only: [:search]
  skip_before_action :verify_authenticity_token, only: %i[toggle frequency destroy]

  def search
    @addressees = Emails::Addressee.all.order(:name)
  end

  def list
    @types = Emails::Type.all.order(:name)
    @preferences = if params[:token].present?
                     Emails::Preference.joins(:addressee).where(emails_addressees: { manage_key: params[:token] })
                   elsif params[:addressee].present? && current_user&.has_role?(:admin) # only admins are allowed to view prefs for arbitrary users
                     Emails::Preference.where(emails_addressee_id: params[:addressee])
                   elsif params[:email].present? && current_user&.has_role?(:admin) # likewise
                     Emails::Preference.joins(:addressee).where(emails_addressees: { email_address: params[:email] })
                   end.order(Arel.sql('emails_type_id ASC, reference_type ASC, reference_id ASC, created_at ASC'))
                   .group_by(&:emails_type_id)
  end

  def toggle
    @preference.update(enabled: params[:enabled])
    render json: { status: 'Accepted' }, status: 202
  end

  def frequency
    @preference.update(frequency: params[:frequency])
    render json: { status: 'Accepted' }, status: 202
  end

  def destroy
    @preference.destroy
    render json: { status: 'Accepted' }, status: 202
  end

  private

  def set_preference
    @preference = Emails::Preference.find params[:id]
  end

  def verify_permissions
    return if current_user&.has_role?(:admin) || params[:token] == @preference.addressee.manage_key

    redirect_to missing_privileges_path('admin')
  end
end

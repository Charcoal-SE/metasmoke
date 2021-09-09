# frozen_string_literal: true

class DomainGroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy emails]
  before_action :authenticate_user!, only: %i[new create edit update destroy emails]
  before_action :verify_core, only: %i[new create edit update]
  before_action :verify_admin, only: :destroy

  def index
    @groups = DomainGroup.joins('LEFT JOIN domain_groups_spam_domains j ON domain_groups.id = j.domain_group_id')
                         .select(Arel.sql('domain_groups.*, COUNT(j.spam_domain_id) as domain_count'))
                         .group(Arel.sql('domain_groups.id')).order(:name).paginate(page: params[:page], per_page: 50)
  end

  def new
    @group = DomainGroup.new
  end

  def create
    @group = DomainGroup.new group_params
    unless valid_regex? @group.regex
      flash[:danger] = "Invalid regex `#{@group.regex}`."
      render :new
      return
    end

    if @group.save
      regex = Regexp.new @group.regex
      domains = SpamDomain.all.reject { |d| regex.match(d.domain).nil? }
      @group.spam_domains += domains
      redirect_to domain_group_path(@group)
    else
      render :new
    end
  end

  def show
    @domains = @group.spam_domains.includes(:domain_tags).paginate(page: params[:page], per_page: 50)
  end

  def edit; end

  def update
    unless group_params[:regex] && valid_regex?(group_params[:regex])
      flash[:danger] = "Invalid regex `#{group_params[:regex]}`."
      render :edit
      return
    end

    if @group.update group_params
      redirect_to domain_group_path(@group)
    else
      render :edit
    end
  end

  def destroy
    if @group.destroy
      redirect_to domain_groups_path
    else
      flash[:danger] = 'Failed to remove the domain group. Tell Undo.'
      render :show
    end
  end

  def emails
    success = Emails::Preference.sign_up_for_emails(
      email_address: params[:addressee_email],
      name: params[:addressee_name],
      type_short: 'domain-group-summary',
      frequency_days: params[:frequency],
      reference: @group,
      consent_via: 'admin',
      consent_comment: "admin user.id = #{current_user.id}\ncomment: #{params[:consent_comment]}"
    )
    if success
      flash[:success] = 'Created subscription.'
    else
      flash[:danger] = 'Failed to create subscription. Poke somebody.'
    end
    redirect_back fallback_location: domain_group_path(@group)
  end

  private

  def valid_regex?(regex)
    Regexp.new(regex) if regex.present?

    true
  rescue RegexpError
    false
  end

  def group_params
    params.require(:domain_group).permit(:name, :regex)
  end

  def set_group
    @group = DomainGroup.find params[:id]
  end
end

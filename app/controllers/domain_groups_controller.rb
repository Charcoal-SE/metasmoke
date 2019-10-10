# frozen_string_literal: true

class DomainGroupsController < ApplicationController
  before_action :set_group, only: %i[show edit update destroy emails]
  before_action :verify_core, only: %i[new create edit update]

  def index
    @groups = DomainGroup.joins('INNER JOIN domain_groups_spam_domains j ON domain_groups.id = j.domain_group_id')
                         .select(Arel.sql('domain_groups.*, COUNT(j.spam_domain_id) as domain_count'))
                         .group(Arel.sql('domain_groups.id')).order(:name).paginate(page: params[:page], per_page: 50)
  end

  def new
    @group = DomainGroup.new
  end

  def create
    @group = DomainGroup.new group_params
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

  def group_params
    params.require(:domain_group).permit(:name, :regex)
  end

  def set_group
    @group = DomainGroup.find params[:id]
  end
end

class DomainGroupsMailer < ApplicationMailer
  default from: 'Charcoal SpamWatch Alerts <alerts@charcoal-se.org>'

  def domain_group_summary(preference)
    @type = preference.type
    @addressee = preference.addressee
    @group = preference.reference

    @last_email_date = (Date.today - preference.frequency.days).to_time.iso8601
    @domains = DomainGroup.where(id: @group.id).joins(Arel.sql('INNER JOIN domain_groups_spam_domains j ON j.domain_group_id = domain_groups.id'))
                          .where('j.created_at >= ?', @last_email_date)

    @preference.update(next: (Date.today + preference.frequency.days).to_time.iso8601)

    mail(to: @addressee.email_address, subject: "Your SpamWatch summary for #{@group.name}")
  end
end

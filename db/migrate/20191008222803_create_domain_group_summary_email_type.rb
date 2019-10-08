class CreateDomainGroupSummaryEmailType < ActiveRecord::Migration[5.2]
  def change
    Emails::Type.create(
      name: 'Domain group summaries',
      short_name: 'domain-group-summary',
      description: 'Round-up of spam that\'s been seen under a particular domain or group of domains.',
      mailer: 'DomainGroup',
      method_name: 'domain_group_summary'
    )
  end
end

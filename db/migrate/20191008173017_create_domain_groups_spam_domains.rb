class CreateDomainGroupsSpamDomains < ActiveRecord::Migration[5.2]
  def change
    create_table :domain_groups_spam_domains, id: false, primary_key: [:domain_group_id, :spam_domain_id] do |t|
      t.bigint :domain_group_id
      t.bigint :spam_domain_id
    end
  end
end

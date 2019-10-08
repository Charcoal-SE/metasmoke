class AddTimestampsToDomainGroupsSpamDomains < ActiveRecord::Migration[5.2]
  def change
    change_table :domain_groups_spam_domains do |t|
      t.timestamps default: -> { 'current_timestamp' }
    end
  end
end

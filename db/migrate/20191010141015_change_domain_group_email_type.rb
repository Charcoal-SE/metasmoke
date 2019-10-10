class ChangeDomainGroupEmailType < ActiveRecord::Migration[5.2]
  def change
    Emails::Type['domain-group-summary'].update(mailer: 'DomainGroups')
  end
end

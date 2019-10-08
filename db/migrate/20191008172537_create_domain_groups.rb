class CreateDomainGroups < ActiveRecord::Migration[5.2]
  def change
    create_table :domain_groups do |t|
      t.string :name
      t.string :regex

      t.timestamps
    end
  end
end

class AddSpecialToDomainTags < ActiveRecord::Migration[5.2]
  def change
    add_column :domain_tags, :special, :boolean, default: false
  end
end

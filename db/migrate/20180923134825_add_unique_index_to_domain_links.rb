class AddUniqueIndexToDomainLinks < ActiveRecord::Migration[5.2]
  def change
    # We kinda have to remove any duplicate records before we can create a unique index,
    # so... here's some more fun SQL
    DomainLink.select(Arel.sql('left_id, right_id, COUNT(*) AS count')).group(Arel.sql('left_id, right_id'))
              .having(Arel.sql('COUNT(*) > 1')).each do |duped|
      DomainLink.where(left_id: duped.left_id, right_id: duped.right_id).limit(duped.count - 1).destroy_all
    end

    add_index :domain_links, [:left_id, :right_id], unique: true
  end
end

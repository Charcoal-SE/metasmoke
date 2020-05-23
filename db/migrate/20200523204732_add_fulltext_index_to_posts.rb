class AddFulltextIndexToPosts < ActiveRecord::Migration[5.2]
  def change
    # This is going to take FUCKING FOREVER on prod. Prepare for downtime.
    add_index :posts, :body, type: :fulltext
  end
end

class AddNumberToPullRequests < ActiveRecord::Migration[5.0]
  def change
    add_column :pull_requests, :number, :integer
  end
end

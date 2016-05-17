class AddCiurlToCommitStatus < ActiveRecord::Migration[5.0]
  def change
    add_column :commit_statuses, :ci_url, :string
  end
end

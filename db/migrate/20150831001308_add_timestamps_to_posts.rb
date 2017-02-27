class AddTimestampsToPosts < ActiveRecord::Migration[4.2]
    def change
        change_table(:posts) { |t| t.timestamps }
    end
end

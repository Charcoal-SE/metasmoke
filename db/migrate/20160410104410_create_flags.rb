class CreateFlags < ActiveRecord::Migration[5.0]
  def change
    create_table :flags do |t|
      t.string :reason
      t.string :user_id

      t.timestamps
    end
  end
end

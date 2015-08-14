class CreateRegexes < ActiveRecord::Migration
  def change
    create_table :regexes do |t|
      t.string :reason

      t.timestamps null: false
    end
  end
end

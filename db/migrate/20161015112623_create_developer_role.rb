class CreateDeveloperRole < ActiveRecord::Migration[5.0]
  def up
    Role.create(:name => 'developer')
  end

  def down
    Role.where(:name => 'developer').destroy_all!
  end
end

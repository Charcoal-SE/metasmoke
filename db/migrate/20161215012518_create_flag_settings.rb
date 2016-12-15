class CreateFlagSettings < ActiveRecord::Migration[5.0]
  def change
    create_table :flag_settings do |t|
      t.string :name
      t.string :value

      t.timestamps
    end

    reversible do |direction|
      direction.up do
        FlagSetting.create(:name => "flagging_enabled", :value => "0")
      end
    end
  end
end

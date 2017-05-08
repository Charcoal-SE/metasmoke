class AddWeightToReason < ActiveRecord::Migration[5.0]
  def change
    add_column :reasons, :weight, :int, default: 0 
    # Weight is an integer between 0 and 100, defined as (tp count) / (total)
    
    ReasonsHelper.calculate_weights_for_flagging
  end
end

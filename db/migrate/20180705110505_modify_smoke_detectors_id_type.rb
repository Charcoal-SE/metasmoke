class ModifySmokeDetectorsIdType < ActiveRecord::Migration[5.2]
  def change
    change_column :smoke_detectors, :id, :bigint
  end
end

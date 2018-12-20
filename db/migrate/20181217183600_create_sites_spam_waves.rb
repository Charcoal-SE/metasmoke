class CreateSitesSpamWaves < ActiveRecord::Migration[5.2]
  def change
    create_table :sites_spam_waves, id: false do |t|
      t.bigint :site_id, null: false
      t.bigint :spam_wave_id, null: false
    end
    execute 'ALTER TABLE sites_spam_waves ADD PRIMARY KEY (site_id, spam_wave_id)'
  end
end

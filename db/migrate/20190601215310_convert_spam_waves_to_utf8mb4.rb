class ConvertSpamWavesToUtf8mb4 < ActiveRecord::Migration[5.2]
  def change
      execute 'ALTER TABLE `spam_waves` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_bin'
  end
end

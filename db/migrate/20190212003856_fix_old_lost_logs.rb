class FixOldLostLogs < ActiveRecord::Migration[5.2]
  def change
    redis(logger: true).rename "requests/status/", "requests/status/INC" if redis(logger: true).exists "requests/status/"
  end
end

# frozen_string_literal: true

EXCLUDE_TABLES = %w[ar_internal_metadata flags github_tokens schema_migrations].freeze
EXCLUDE_COLUMNS = {
  'api_keys' => ['key'],
  'api_tokens' => %w[code token],
  'audits' => ['remote_address'],
  'smoke_detectors' => ['access_token'],
  'users' => %w[email encrypted_password reset_password_token encrypted_api_token two_factor_token enabled_2fa salt iv eu_resident privacy_accepted]
}.freeze

tables = ActiveRecord::Base.connection.tables
queries = []

queries << "CREATE USER IF NOT EXISTS metasmoke_blazer@localhost IDENTIFIED BY 'zFpc8tw7CdAuXizX';"

tables.each do |t|
  next if EXCLUDE_TABLES.include? t
  columns = ActiveRecord::Base.connection.columns(t).map(&:name) - (EXCLUDE_COLUMNS[t] || [])
  queries << "CREATE OR REPLACE VIEW p_#{t} AS SELECT #{columns.join(', ')} FROM #{t};"
  queries << "GRANT SELECT ON #{ActiveRecord::Base.connection.current_database}.p_#{t} TO metasmoke_blazer@localhost;"
end

queries.each do |q|
  ActiveRecord::Base.connection.execute q
end

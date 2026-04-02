# frozen_string_literal: true

require 'sequel'

DB = Sequel.connect(
  Config.database_url,
  max_connections: Config.production? ? 10 : 5,
  pool_timeout: 10,
  logger: Config.development? ? Logger.new($stdout) : nil
)

# Extensions
Sequel.extension :migration
DB.extension :pg_json if DB.adapter_scheme == :postgres

# Freeze schemas in production for performance
DB.freeze if Config.production?

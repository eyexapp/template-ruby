# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
Dotenv.load(".env.#{ENV.fetch('RACK_ENV', 'development')}", '.env')
require_relative 'config/environment'

namespace :db do
  desc 'Create the database'
  task :create do
    url = Config.database_url
    db_name = URI.parse(url).path.delete_prefix('/')
    base_url = url.sub("/#{db_name}", '/postgres')

    conn = Sequel.connect(base_url)
    conn.execute("CREATE DATABASE #{conn.literal(db_name.to_sym)}")
    conn.disconnect
    puts "Created database: #{db_name}"
  rescue Sequel::DatabaseError => e
    puts "Database already exists or error: #{e.message}"
  end

  desc 'Drop the database'
  task :drop do
    url = Config.database_url
    db_name = URI.parse(url).path.delete_prefix('/')
    base_url = url.sub("/#{db_name}", '/postgres')

    conn = Sequel.connect(base_url)
    conn.execute("DROP DATABASE IF EXISTS #{conn.literal(db_name.to_sym)}")
    conn.disconnect
    puts "Dropped database: #{db_name}"
  end

  desc 'Run pending migrations'
  task :migrate do
    require 'sequel'
    Sequel.extension :migration
    db = Sequel.connect(Config.database_url)
    Sequel::Migrator.run(db, 'db/migrations')
    puts 'Migrations complete'
  end

  desc 'Rollback last migration'
  task :rollback do
    require 'sequel'
    Sequel.extension :migration
    db = Sequel.connect(Config.database_url)
    Sequel::Migrator.run(db, 'db/migrations', target: 0)
    puts 'Rollback complete'
  end

  desc 'Run seed data'
  task :seed do
    require_relative 'config/application'
    require_relative 'db/seeds'
    puts 'Seed complete'
  end

  desc 'Reset database (drop + create + migrate + seed)'
  task reset: %i[drop create migrate seed]

  desc 'Create a new migration file'
  task :create_migration, [:name] do |_t, args|
    name = args[:name] || raise('Usage: rake db:create_migration[migration_name]')
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    filename = "db/migrations/#{timestamp}_#{name}.rb"

    File.write(filename, <<~RUBY)
      # frozen_string_literal: true

      Sequel.migration do
        up do
        end

        down do
        end
      end
    RUBY

    puts "Created migration: #{filename}"
  end
end

desc 'Run tests'
task :spec do
  sh 'bundle exec rspec'
end

task default: :spec

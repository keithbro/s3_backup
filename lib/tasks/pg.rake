require 'pry'
require 's3_backup'

namespace :s3_backup do
  namespace :pg do

    desc 'Backup, obfuscate & compress Postgres database to s3'
    task :backup, [:database] do |_task, args|
      raise 'You need to specify a database' unless args[:database]

      S3Backup.pg_backup! args[:database]
    end

    desc 'Import Postgres database from s3'
    task :import, [:pg_database] do |_task, args|
      raise 'You need to specify a pg database' unless args[:pg_database]

      S3Backup.pg_import! args[:pg_database]
    end

    desc 'Download the most recent backup from S3'
    task :download, [:pg_database,:filename] do |_task, args|
      raise 'You need to specify a pg database' unless args[:pg_database]
      filename = args[:filename] || "/tmp/#{pg_database_name}-#{Time.current.strftime('%Y%m%dT%H%M%S')}.sql.gz"
      
      S3Backup.pg_download! args[:pg_database], filename
      puts "Downloaded backup to #{filename}"
    end
  end
end

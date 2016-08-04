require 's3_backup'

namespace :s3_backup do
  namespace :redis do

    desc 'Backup & compress Redis database to s3'
    task :backup do |_task, _args|
      S3Backup.redis_backup!
    end

    desc 'Import Redis database from s3'
    task :import, [:redis_environement] do |_task, args|
      raise 'You need to specify a redis environement' unless args[:redis_environement]

      S3Backup.redis_import! args[:redis_environement]
    end

  end
end

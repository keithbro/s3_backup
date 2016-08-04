require 's3_backup/config'
require 's3_backup/s3'

require 's3_backup/pg/obfuscate'
require 's3_backup/pg/backup'
require 's3_backup/pg/import'

require 's3_backup/redis/backup'
require 's3_backup/redis/import'

require 's3_backup/railtie' if defined?(Rails)

module S3Backup
  class << self

    def pg_backup!(database_name)
      require_s3_params
      Config.requires!(:pg_host, :pg_user, :pg_password, :s3_pg_path, :tables)

      backup = Pg::Backup.new(database_name)
      backup.now!
    end

    def pg_import!(pg_database_name)
      raise 'Need to be run in a rails project' unless defined?(Rails)

      require_s3_params
      Config.requires!(:s3_pg_path)

      import = Pg::Import.new(pg_database_name)
      import.now!
    end

    def redis_backup!
      require_s3_params
      Config.requires!(:redis_dump_path, :s3_redis_path)

      backup = Redis::Backup.new
      backup.now!
    end

    def redis_import!(redis_evironement)
      raise 'Import only work with redis installed by brew' if Dir['/usr/local/Cellar/redis/*'].blank?

      require_s3_params
      Config.requires!(:s3_redis_path)

      import = Redis::Import.new(redis_evironement)
      import.now!
    end

    private

    def require_s3_params
      Config.load!('config/s3_backup_obfuscate.yml')

      Config.requires!(:aws_access_key_id, :aws_secret_access_key, :bucket, :aws_region, :s3_keep)
    end

  end
end

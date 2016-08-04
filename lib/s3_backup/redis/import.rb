require 'zlib'

module S3Backup
  module Redis
    class Import
      STOP_REDIS_COMMAND  = 'brew services stop redis'.freeze
      START_REDIS_COMMAND = 'brew services start redis'.freeze

      attr_reader :redis_evironement, :redis_s3_file_name, :redis_dump_file_path

      def initialize(redis_evironement)
        @redis_evironement    = redis_evironement
        @redis_s3_file_name   = "redis-#{redis_evironement}"
        @redis_dump_file_path = '/usr/local/var/db/redis/dump.rdb'
      end

      def now!
        puts 'Stop redis database ...'
        stop_redis_database
        puts 'Downloading redis database ...'
        S3Backup::S3.new.download!(redis_s3_file_name, Config.s3_redis_path, redis_dump_s3_file.path)
        umcompress_file
        copy_file
        puts 'Start redis database ...'
        start_redis_database
        clean_env
        puts '🍺  Done!'
      end

      private

      def redis_dump_s3_file
        @redis_dump_s3_file ||= Tempfile.new("#{redis_s3_file_name}_compressed")
      end

      def redis_dump_file
        @redis_dump_file ||= Tempfile.new(redis_s3_file_name)
      end

      def umcompress_file
        file = File.open(redis_dump_file.path, 'w')

        Zlib::GzipReader.open(redis_dump_s3_file.path) do |gz|
          file.write gz.read
        end
        file.close
      end

      def copy_file
        `mv #{redis_dump_file.path} #{redis_dump_file_path}`
      end

      def stop_redis_database
        Bundler.with_clean_env do
          `#{STOP_REDIS_COMMAND} 2> /dev/null`
        end
      end

      def start_redis_database
        Bundler.with_clean_env do
          `#{START_REDIS_COMMAND} 2> /dev/null`
        end
      end

      def clean_env
        redis_dump_file.unlink
        redis_dump_s3_file.unlink
      end

    end
  end
end

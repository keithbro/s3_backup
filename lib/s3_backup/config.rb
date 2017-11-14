# rubocop:disable Style/RescueModifier
require 'pry' rescue nil
# rubocop:enable Style/RescueModifier

require 'erb'
require 'yaml'
require 'English'

module S3Backup
  class Config
    class << self

      attr_accessor :pg_host
      attr_accessor :pg_user
      attr_accessor :pg_password
      attr_accessor :redis_dump_path
      attr_accessor :aws_access_key_id
      attr_accessor :aws_secret_access_key
      attr_accessor :bucket
      attr_accessor :aws_region
      attr_accessor :s3_pg_path
      attr_accessor :s3_redis_path
      attr_accessor :s3_keep
      attr_accessor :tables

      def load!(file_path)
        template       = ERB.new File.new(file_path).read
        @configuration = YAML.load(template.result(binding))

        self.pg_host     = config('pg_database', 'host')
        self.pg_user     = config('pg_database', 'user')
        self.pg_password = config('pg_database', 'password')

        self.redis_dump_path = config('redis', 'dump_path')

        self.aws_access_key_id     = config('s3', 'aws_access_key_id')
        self.aws_secret_access_key = config('s3', 'aws_secret_access_key')
        self.bucket                = config('s3', 'bucket')
        self.aws_region            = config('s3', 'aws_region')
        self.s3_keep               = config('s3', 'keep')
        self.s3_pg_path            = config('s3', 'pg_path')
        self.s3_redis_path         = config('s3', 'redis_path')

        self.tables = config('tables') || {}

        true
      end

      def requires!(*args)
        args.each do |argv|
          raise "Configuration missing: #{argv}" unless Config.send(argv)
        end
        true
      end

      def config(*args)
        args.inject(@configuration) do |hash, key|
          (hash.is_a?(Hash) && hash[key]) || nil
        end
      end

    end
  end
end

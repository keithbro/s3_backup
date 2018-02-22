require 'zlib'

module S3Backup
  module Pg
    class Import
      attr_reader :pg_database_name, :database

      def initialize(pg_database_name)
        @pg_database_name = pg_database_name

        config = Rails.configuration.database_configuration
        @database = config[Rails.env]['database']
      end

      def now!
        puts 'Setup local database ...'
        setup_local_database
        puts 'Downloading pg database ...'
        S3Backup::Storage::S3.new.download!(pg_database_name, Config.s3_pg_path, pg_dump_s3_file.path)
        umcompress_file
        puts "Loading data in #{database} ..."
        load_file
        clean_env
        puts '🍺  Done!'
      end

      private

      def pg_dump_s3_file
        @pg_dump_s3_file ||= Tempfile.new(pg_database_name + '_compressed')
      end

      def pg_dump_file
        @pg_dump_file ||= Tempfile.new(pg_database_name)
      end

      def umcompress_file
        file = File.open(pg_dump_file.path, 'w')

        Zlib::GzipReader.open(pg_dump_s3_file.path) do |gz|
          file.write gz.read
        end
        file.close
      end

      def load_file
        `psql -d #{database} -f #{pg_dump_file.path} 2> /dev/null`
      end

      def setup_local_database
        Rake::Task['db:drop'].invoke
        Rake::Task['db:create'].invoke
      end

      def clean_env
        pg_dump_file.unlink
        pg_dump_s3_file.unlink
      end

    end
  end
end

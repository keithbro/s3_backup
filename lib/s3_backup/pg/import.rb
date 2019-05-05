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
        puts 'Downloading pg database ...'
        S3Backup::Storage::S3.new.download!(pg_database_name, Config.s3_pg_path, pg_dump_s3_file.path)
        puts "Loading data in #{database} ..."
        load_file
        puts "Cleaning up environment..."
        clean_env
        puts '🍺  Done!'
      end

      private

      def pg_dump_s3_file
        @pg_dump_s3_file ||= Tempfile.new(pg_database_name + '_compressed')
      end

      def load_file
        `pg_restore -O -c -d #{database} < #{pg_dump_s3_file.path}`

        abort "Failed to complete pg_restore. Return code #{$CHILD_STATUS}" unless $CHILD_STATUS == 0
      end

      def clean_env
        pg_dump_s3_file.unlink
      end

    end
  end
end

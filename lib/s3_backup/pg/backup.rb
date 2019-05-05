module S3Backup
  module Pg
    class Backup
      attr_reader :db_name

      def initialize(db_name)
        @db_name = db_name
      end

      def now!
        puts 'Setup environment'
        set_pg_password_env
        puts 'Starting downloading dump ...'
        dump_database
        puts 'Dump downloaded.'
        puts 'Upload to S3 ...'
        S3Backup::Storage::S3.new.upload!(File.basename(pg_dump_file), Config.s3_pg_path, pg_dump_file.path)
        puts 'Uploaded.'
        puts 'Cleaning up environment...'
        clean_env
        S3Backup::Storage::S3.new.clean!(db_name, Config.s3_pg_path)
        puts 'Done.'
      end

      private

      def set_pg_password_env
        ENV['PGPASSWORD'] = Config.pg_password
      end

      def dump_database
        `pg_dump -h #{Config.pg_host} -U #{Config.pg_user} -d #{db_name} | gzip > #{pg_dump_file.path}`

        abort "Failed to pg_dump. Return code #{$CHILD_STATUS}" unless $CHILD_STATUS == 0
      end

      def pg_dump_file
        @pg_dump_file ||= Tempfile.new(db_name)
      end

      def clean_env
        pg_dump_file.unlink
        ENV['PGPASSWORD'] = ''
      end

    end
  end
end

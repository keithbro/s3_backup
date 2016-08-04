require 'fog'
require 'zlib'
require 'ruby-progressbar'

module S3Backup
  class S3

    attr_reader :connection

    def initialize
      @connection = Fog::Storage.new(
        provider:              'AWS',
        aws_access_key_id:     Config.aws_access_key_id,
        aws_secret_access_key: Config.aws_secret_access_key,
        region:                Config.aws_region
      )
    end

    def upload!(file_name, bucket_path, file_path)
      directory = @connection.directories.get(Config.bucket)

      directory.files.create(
        key:    File.join(bucket_path, file_name),
        body:   File.open(file_path),
        public: false
      )

      true
    end

    def download!(database_name, bucket_path, file_path)
      progress_bar
      prefix = File.join(bucket_path, database_name)
      directory = connection.directories.get(Config.bucket, prefix: prefix)

      s3_backup_file = directory.files.sort_by(&:last_modified).reverse.first

      raise "#{database_name} file not found on s3" unless s3_backup_file

      file = File.open(file_path, 'wb')
      directory.files.get(s3_backup_file.key) do |chunk, remaining_bytes, total_bytes|
        update_progress_bar(total_bytes, remaining_bytes)
        file.write chunk
      end
      file.close

      true
    end

    def clean!(base_name, bucket_path)
      prefix = File.join(bucket_path, base_name)
      directory = connection.directories.get(Config.bucket, prefix: prefix)

      s3_files = directory.files.sort_by(&:last_modified).reverse
      files_to_remove = s3_files[Config.s3_keep..-1]

      return true if files_to_remove.blank?

      files_to_remove.each(&:destroy)

      true
    end

    private

    def progress_bar
      @progress_bar ||= ProgressBar.create(
        format:         "%a %b\u{15E7}%i %p%% %t",
        progress_mark:  ' ',
        remainder_mark: "\u{FF65}"
      )
    end

    def update_progress_bar(total, remaining)
      progress_bar.progress = (((total - remaining) * 100) / total).to_i
    end

  end
end

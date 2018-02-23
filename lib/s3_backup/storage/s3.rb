require 'aws-sdk-s3'
require 'zlib'
require 'ruby-progressbar'

module S3Backup
  module Storage
    class S3

      attr_reader :connection

      def initialize
        @connection = Aws::S3::Client.new(
          credentials: Aws::Credentials.new(
            Config.aws_access_key_id,
            Config.aws_secret_access_key
          ),
          region:              Config.aws_region,
          endpoint:            Config.aws_endpoint,
          stub_responses:      Config.aws_stub_responses
        )
      end

      def upload!(file_name, bucket_path, file_path)
        upload_options = {
          bucket: Config.bucket,
          key: File.join(bucket_path, file_name),
          body: File.open(file_path)
        }

        upload_options[:server_side_encryption] = Config.aws_server_side_encryption if Config.aws_server_side_encryption
        @connection.put_object(upload_options)
        
        true
      end

      def download!(database_name, bucket_path, file_path)
        prefix = File.join(bucket_path, database_name)
        s3_backup_file = @connection.list_objects(bucket: Config.bucket, prefix: prefix).contents.sort_by(&:last_modified).reverse.first

        raise "#{database_name} file not found on s3" unless s3_backup_file

        file = File.open(file_path, 'wb')
        puts "File size: #{(s3_backup_file.size.to_f / 1024 / 1024).round(4)}MB, writing to #{file_path}"
        total_bytes = s3_backup_file.size
        remaining_bytes = s3_backup_file.size
        progress_bar
        
        @connection.get_object(bucket: Config.bucket, key: s3_backup_file.key) do |chunk|
          update_progress_bar(total_bytes, remaining_bytes)
          file.write chunk
          remaining_bytes -= chunk.size
        end
        file.close

        true
      end

      def clean!(base_name, bucket_path)
        prefix = File.join(bucket_path, base_name)

        s3_files = @connection.list_objects(bucket: Config.bucket, prefix: prefix).contents.sort_by(&:last_modified).reverse
        files_to_remove = s3_files[(Config.s3_keep || 1)..-1]

        return true if files_to_remove.nil? || files_to_remove.empty?

        @connection.delete_objects(
          bucket: Config.bucket,
          delete: {
            objects: files_to_remove.map {|f| {key: f.key} }
          }
        )

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
end

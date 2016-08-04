require 'zlib'

module S3Backup
  module Redis
    class Backup

      def now!
        puts 'Compressing dump ...'
        compress_file
        puts 'Compressed.'
        puts 'Upload to S3 ...'
        S3Backup::S3.new.upload!(compressed_file_name, Config.s3_redis_path, compressed_file.path)
        puts 'Uploaded.'
        puts 'Clean environement.'
        clean_env
        S3Backup::S3.new.clean!(base_s3_name, Config.s3_redis_path)
      end

      private

      def compress_file
        file = Zlib::GzipWriter.open(compressed_file.path)

        File.open(Config.redis_dump_path).each do |line|
          file.write(line)
        end
        file.close
      end

      def base_s3_name
        "redis-#{Rails.env}"
      end

      def compressed_file_name
        @compressed_file_name ||= "#{base_s3_name}-#{Time.now.to_i}.gz"
      end

      def compressed_file
        @compressed_file ||= Tempfile.new(compressed_file_name)
      end

      def clean_env
        compressed_file.unlink
      end

    end
  end
end

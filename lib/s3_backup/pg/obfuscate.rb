require 'zlib'
require 'faker'

module S3Backup
  module Pg
    class Obfuscate

      LINE_SEPARATOR   = "\t".freeze
      END_OF_STATEMENT = '\.'.freeze

      attr_reader :dump_file, :file_path

      def initialize(dump_file, file_path)
        @dump_file = dump_file
        @file_path = file_path
      end

      def obfuscate_dump!
        file = Zlib::GzipWriter.open(file_path)

        File.open(dump_file).each do |line|
          file.write(obfuscate_line(line.chomp) + "\n")
        end
        file.close
      end

      private

      def obfuscate_line(line)
        if line == END_OF_STATEMENT
          @inside_copy_statement = false
        elsif table_to_obfuscate(line)
          pepare_statement_line_to_replace(line)
        elsif @inside_copy_statement && !line.include?(@exception)
          line_split = line.split(LINE_SEPARATOR)

          @replacements.each do |position, type|
            line_split[position] = replace_value(type)
          end

          return line_split.join(LINE_SEPARATOR)
        end

        line
      end

      # INFO:
      # Test if the line start with COPY
      # return false if the table is not in the configration file
      # return the name of the table
      #
      def table_to_obfuscate(line)
        return false if line[0..3] != 'COPY'

        Config.tables.keys.each do |table_name|
          return table_name if line.include?("COPY #{table_name} (")
        end

        false
      end

      # INFO:
      # Pepare variables for the next insert lines
      #
      def pepare_statement_line_to_replace(line)
        @table_name   = table_to_obfuscate(line)
        column_names  = line[/\(([^)]+)\)/].tr('(),', '').split
        @replacements = {}

        column_names.each_with_index do |column_name, index|
          if Config.tables[@table_name]['columns'].key?(column_name)
            @replacements[index] = Config.tables[@table_name]['columns'][column_name]
            @exception           = Config.tables[@table_name]['exception']
          end
        end

        @inside_copy_statement = true
      end

      def replace_value(type)
        case type
        when 'email'
          Faker::Internet.email("#{Faker::Name.name}_#{rand(100_000)}")
        when 'first_name'
          Faker::Name.first_name
        when 'last_name'
          Faker::Name.last_name
        when 'name'
          Faker::Name.name
        else
          'not defined'
        end
      end

    end
  end
end

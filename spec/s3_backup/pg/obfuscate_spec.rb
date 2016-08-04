require 'spec_helper'

describe S3Backup::Pg::Obfuscate do
  let(:configuration_file) { 'spec/fixtures/obfuscate_default.yml' }

  before { S3Backup::Config.load!(configuration_file) }

  subject(:obfuscate) { S3Backup::Pg::Obfuscate.new(nil, nil) }

  describe 'private#obfuscate_line' do
    context 'parse line' do
      let(:table_header) { "COPY users (id, name, email, created_at, updated_at) FROM stdin;" }
      let(:line_table)   { "42\tTom Test\ttom@test.me\t2016-06-15 04:23:00.121\t2016-06-23 07:08:02.08" }

      before { obfuscate.send(:obfuscate_line, table_header) }

      it { expect(obfuscate.send(:obfuscate_line, line_table)).to_not include('tom@test.me') }
      it { expect(obfuscate.send(:obfuscate_line, line_table)).to_not include('Tom Test') }
    end

    context 'parse with exception line' do
      let(:table_header) { "COPY users (id, name, email, created_at, updated_at) FROM stdin;" }
      let(:line_table)   { "42\tTom Test\ttom@mycompany.me\t2016-06-15 04:23:00.121\t2016-06-23 07:08:02.08" }

      before { obfuscate.send(:obfuscate_line, table_header) }

      it { expect(obfuscate.send(:obfuscate_line, line_table)).to include('tom@mycompany.me') }
      it { expect(obfuscate.send(:obfuscate_line, line_table)).to include('Tom Test') }
    end

    context 'if table is not difined' do
      let(:table_header) { "COPY accounts (id, name, email, created_at, updated_at) FROM stdin;" }
      let(:line_table)   { "42\tTom Test\ttom@test.me\t2016-06-15 04:23:00.121\t2016-06-23 07:08:02.08" }

      before { obfuscate.send(:obfuscate_line, table_header) }

      it { expect(obfuscate.send(:obfuscate_line, line_table)).to include('tom@test.me') }
      it { expect(obfuscate.send(:obfuscate_line, line_table)).to include('Tom Test') }
    end
  end

end

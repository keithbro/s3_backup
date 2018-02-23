require 'spec_helper'

describe S3Backup::Storage::S3 do
  let(:configuration_file) { 'spec/fixtures/obfuscate_default.yml' }

  before { S3Backup::Config.load!(configuration_file) }
  subject(:s3) { S3Backup::Storage::S3.new }

  describe '#upload' do
    before do
      client = s3.instance_variable_get('@connection')
      client.stub_responses(:put_object)
    end

    it 'should upload a file via AWS S3' do
      s3.upload!('test', 'test-bucket', 'spec/fixtures/obfuscate_default.yml')
    end
  end

  describe '#download' do
    before do
      client = s3.instance_variable_get('@connection')
      client.stub_responses(:list_objects,
                            {
                              contents:  [
                                {
                                  key: 'offers/1/img.jgp',
                                  last_modified: Time.now,
                                  size: 1234
                                }
                              ]
                            })
    end

    it 'should retrieve the latest file' do
      temp = Tempfile.new('s3-backup')
      expect(s3.download!('test', 'test-bucket', temp.path)).to eq(true)
    end
  end

  describe '#clean!' do
    before do
      client = s3.instance_variable_get('@connection')
      client.stub_responses(:list_objects,
                            {
                              contents:  [
                                {
                                  key: 'test1-012.tgz',
                                  last_modified: Time.now,
                                  size: 1234
                                },
                                {
                                  key: 'test1-123.tgz',
                                  last_modified: Time.now - 3600,
                                  size: 1234
                                }
                              ]
                            })
    end

    it 'should clean the old files' do
      s3.clean!('test', 'test-bucket')
    end
  end

end

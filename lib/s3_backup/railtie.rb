require 'rails'

module S3Backup
  class Railtie < Rails::Railtie
    railtie_name :s3_backup

    rake_tasks do
      load 'tasks/pg.rake'
      load 'tasks/redis.rake'
    end
  end
end

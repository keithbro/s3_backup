# S3 Backup

## Postgres

#### Backup
```
rake s3_backup:pg:backup[db_staging]
```

#### Import
```
rake s3_backup:pg:import[db_staging]
```

## Redis

#### Backup
```
rake s3_backup:redis:backup
```

#### Import
```
rake s3_backup:redis:import[staging]
```

## Configuration file

```yaml
---

pg_database:
  host: <%= ENV['DATABASE_HOST'] %>
  user: <%= ENV['DATABASE_USER'] %>
  password: <%= ENV['DATABASE_PASSWORD'] %>

redis:
  dump_path: /var/lib/redis/6379/dump.rdb

s3:
  aws_access_key_id: <%= ENV['AWS_ACCESS_KEY_ID'] %>
  aws_secret_access_key: <%= ENV['AWS_SECRET_ACCESS_KEY'] %>
  bucket: <%= ENV['S3_BUCKET'] %>
  aws_region: <%= ENV['AWS_REGION'] %>
  aws_endpoint: <%= ENV['AWS_ENDPOINT'] %>
  server_side_encryption: 'AES256'
  stub_responses: false
  pg_path: rds_backup
  redis_path: redis_backup
  keep: 5

tables:
  users:
    columns:
      first_name: first_name
      last_name: last_name
      email: email
    exception: '@mycompany.me'
```

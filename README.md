# DRI Spotlight

A Spotlight application with DRI branding and functionality. It includes the [spotlight-resources-dri](https://github.com/Digital-Repository-of-Ireland/spotlight-resources-dri) gem for importing DRI objects into an exhibit.

## Configuration

Exhibits need to provide the following configuration files:

* `config/database.yml` - Standard Rails database configuration
* `config/blacklight.yml` - Blacklight solr configuration
* config/initializers/secret_token.rb - Rails secret token

## Development

### Docker

```bash
docker-compose up web # web here means you can start and stop Rails w/o starting or stopping other services. `docker-compose stop` when done shuts everything else down.
```

Once that starts you can view your app in a web browser at localhost:3000

### Requirements
- Redis (for running background jobs with Sidekiq)

See [projectblacklight/spotlight](https://github.com/projectblacklight/spotlight) for additional requirements.

Install dependencies, set up the databases and run migrations:
```console
$ bundle install
$ bundle exec rake db:setup
```

Start a Solr instance:
```console
$ bundle exec solr_wrapper
```

Start the server:
```console
$ bundle exec rails server
```

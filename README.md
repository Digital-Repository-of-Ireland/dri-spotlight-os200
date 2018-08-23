# DRI Spotlight

A Spotlight application with DRI branding and functionality. It includes the [spotlight-resources-dri](https://github.com/Digital-Repository-of-Ireland/spotlight-resources-dri) gem for importing DRI objects into an exhibit.

## Configuration

Exhibits need to provide the following configuration files:

* `config/database.yml` - Standard Rails database configuration
* `config/blacklight.yml` - Blacklight solr configuration
* config/initializers/secret_token.rb - Rails secret token

## Development

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
$ solr_wrapper
```

Start the server:
```console
$ bundle exec rake server
```

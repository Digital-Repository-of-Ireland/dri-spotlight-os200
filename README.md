# DRI Spotlight

A Spotlight application with DRI branding and functionality. It includes the [spotlight-resources-dri](https://github.com/Digital-Repository-of-Ireland/spotlight-resources-dri) gem for importing DRI objects into an exhibit.

## Deploy

### Docker
The application and the full stack it requires can brought up using Docker. Docker and docker-compose will need to be installed to do this. The following command can then be used to start the application for development (i.e. the repository is mounted in the container as a volume):

```bash
# web here means you can start and stop Rails w/o starting or stopping other services. 
# `docker-compose stop` when done shuts everything else down.
docker-compose up web
```

The .env file in the root of the repository can be used to set variables for the services started by Docker.

### Without Docker

- Redis is required (for running background jobs with Sidekiq)

See [projectblacklight/spotlight](https://github.com/projectblacklight/spotlight) for additional requirements.

Exhibits need to provide the following configuration files:

* `config/database.yml` - Standard Rails database configuration
* `config/blacklight.yml` - Blacklight solr configuration
* config/initializers/secret_token.rb - Rails secret token

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

To create an admin user, or to give an existing user an admin role:
```bash
rake spotlight:admin
```


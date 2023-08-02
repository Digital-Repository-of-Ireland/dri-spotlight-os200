source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1'

gem 'activerecord-nulldb-adapter'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
gem 'pg'
# Use Puma as the app server
gem 'puma', '~> 4'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'js_cookie_rails'

gem 'net-smtp'
gem 'rest-client'

# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem "loofah", ">= 2.2.3"
gem "rubyzip", ">= 1.2.2"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
  gem 'dotenv-rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]

gem 'blacklight', ' ~> 7.0'
gem 'blacklight-spotlight', '3.5.0.2'
gem 'blacklight-maps'
group :development, :test do
  gem 'solr_wrapper', '>= 0.3'
end

group :production do
  gem 'mysql2'
end

gem 'spotlight-resources-dri', github: 'Digital-Repository-of-Ireland/spotlight-resources-dri', branch: 'main'

gem 'rsolr', '>= 1.0', '< 3'
gem 'bootstrap', '~> 4.0'
#gem 'bootstrap-sass'
gem 'twitter-typeahead-rails', '0.11.1.pre.corejavascript'
gem 'jquery-rails'
gem 'devise'
gem 'devise-guests', '~> 0.8'
gem 'friendly_id'
gem 'riiif'
gem 'sitemap_generator'
gem 'blacklight-gallery', '~> 4.0'
gem 'openseadragon', '>= 0.2.0'
gem 'blacklight-oembed', '~> 1.0'
gem 'devise_invitable'

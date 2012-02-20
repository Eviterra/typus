source 'http://rubygems.org'

# Declare your gem's dependencies in typus.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

# Database adapters
platforms :jruby do
  gem 'activerecord-jdbcmysql-adapter'
  gem 'activerecord-jdbcpostgresql-adapter'
  gem 'activerecord-jdbcsqlite3-adapter'

  gem 'jruby-openssl' # JRuby limited openssl loaded. http://jruby.org/openssl
end

platforms :ruby do
  gem 'mysql2'
  gem 'pg'
  gem 'sqlite3'
end

# And this stuff needed for the demo application.
gem "acts_as_list"
gem "acts_as_tree"
gem "factory_girl_rails", "~> 1.6.0"
gem "rails-permalink", "~> 1.0.0"
gem "rails-trash", "~> 2.0.0"

# For some reason I also need to define the `jquery-rails` gem here.
gem "jquery-rails"

# Rich Text Editor
gem "ckeditor-rails", "~> 0.0.3"

# Alternative authentication
gem "devise", "~> 2.0.0"

# Asset Management with Dragonfly
gem "dragonfly", "~> 0.9.10"
gem "rack-cache", :require => "rack/cache"

# Asset Management with Paperclip
gem "paperclip", "~> 2.5.2"

# MongoDB
gem "mongoid", "~> 2.4.3"
gem "bson_ext", "~> 1.5.2"

group :test do
  gem "shoulda-context", "~> 1.0.0"
  gem "mocha" # Make sure mocha is loaded at the end ...
end

# Remember to install the Chrome or Safari extension, otherwise it doesn't
# make sense to have this here.
group :development do
  # gem "guard-livereload"
  # gem "rb-fsevent"
  # gem "growl_notify"
end

gem "SystemTimer", :platform => :ruby_18

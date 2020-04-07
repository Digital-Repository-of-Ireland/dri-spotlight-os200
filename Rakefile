# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative 'config/application'

Rails.application.load_tasks

namespace :dri_spotlight do
  desc 'Add application-wide admin privileges to a user'
  task admin: :environment do
    if ENV['SPOTLIGHT_ADMIN_USER'] && ENV['SPOTLIGHT_ADMIN_PASSWORD']
      user = Spotlight::Engine.user_class.find_or_create_by(email: "#{ENV['SPOTLIGHT_ADMIN_USER']}")
      user.password = ENV['SPOTLIGHT_ADMIN_PASSWORD']
      user.save

      Spotlight::Role.create(user: user, resource: Spotlight::Site.instance, role: 'admin')
    end
  end
end

require 'solr_wrapper/rake_task' unless Rails.env.production?

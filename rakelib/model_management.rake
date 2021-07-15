# rake tasks for group and category management
#
desc 'Ontology Group Administration'
namespace :group do
  require 'bundler/setup'
  # Configure the process for the current cron configuration.
  require_relative '../lib/ncbo_cron'
  config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
  abort('Please create a config/config.rb file using the config/config.rb.sample as a template') unless config_exists
  require_relative '../config/config'

  desc 'Create a new ontology group'
  task :create, [:acronym, :name] do |_t, args|
    checkgroup = LinkedData::Models::Group.find(args.acronym).first
    abort("FAILED: The Group #{args.groupname} already exists") unless checkgroup.nil?
    group = LinkedData::Models::Group.new
    group.name = args.name
    group.acronym = args.acronym
    if group.valid?
      group.save
    else
      puts 'FAILED: create new ontology group'
    end
  end
end

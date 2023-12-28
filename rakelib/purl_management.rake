# Task for updating and adding missing purl for all ontologies
#
desc 'Purl Utilities'
namespace :purl do
  require 'bundler/setup'
  # Configure the process for the current cron configuration.
  require_relative '../lib/ncbo_cron'
  config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
  abort('Please create a config/config.rb file using the config/config.rb.sample as a template') unless config_exists
  require_relative '../config/config'

  desc 'update purl for all ontologies'
  task :update_all do
    purl_client = LinkedData::Purl::Client.new
    LinkedData::Models::Ontology.all.each do |ont|
      ont.bring(:acronym)
      acronym = ont.acronym

      if purl_client.purl_exists(acronym)
        puts "#{acronym} exists"
        purl_client.fix_purl(acronym)
      else
        puts "#{acronym} DOES NOT exist"
        purl_client.create_purl(acronym)
      end
    end
  end
end

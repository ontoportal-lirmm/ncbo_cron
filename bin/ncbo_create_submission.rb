#!/usr/bin/env ruby

# Exit cleanly from an early interrupt
Signal.trap("INT") { exit 1 }

# Setup the bundled gems in our environment
require 'bundler/setup'

# Configure the process for the current cron configuration.
require_relative '../lib/ncbo_cron'
config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
abort("Please create a config/config.rb file using the config/config.rb.sample as a template") unless config_exists
require_relative '../config/config'

platform = "local"
if LinkedData.settings.goo_host.include? "stage"
  platform = "stage"
elsif LinkedData.settings.goo_host.include? "prod"
  platform = "prod"
end
puts "Running on #{platform} platform"

if ARGV.length < 2
  puts "Syntax: ./ncbo_create_submission ACRONYM /path/to/ontology administratorUserName"
else

  username = ARGV.pop
  path=ARGV.pop
  acronym=ARGV.pop



  # ontology acronym must be unique
  ont = LinkedData::Models::Ontology.find(acronym.upcase).first

  puts 'Looking for user '+ username
  user = LinkedData::Models::User.find(username).first
  puts user.inspect.to_s

  if ont.nil?
    ont = LinkedData::Models::Ontology.new
    ont.acronym = acronym.upcase
    ont.administeredBy = [ user ]
    ont.name = acronym

    # ontology name must be unique
    ont_names = LinkedData::Models::Ontology.where.include(:name).to_a.map { |o| o.name }
    if ont_names.include?(ont.name)
      puts "Ontology name is already in use by another ontology."
    end

    if ont.valid?
      ont.save
    else
      puts "#{ont.errors}"
    end
  end


  sub = ont.latest_submission(status: :any)

  puts sub.inspect.to_s
  puts ont.inspect.to_s


  pull = NcboCron::Models::OntologyPull.new
  pull.create_submission(ont,sub,path,path.split("/")[-1],logger=nil,
                         add_to_pull=false)

end

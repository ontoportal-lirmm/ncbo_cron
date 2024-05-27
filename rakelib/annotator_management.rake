# rake tasks for annotator management; 
# privides ability to switch and purge alternate annotator redis terms cache instance
#
desc 'Annotator Utilities'
namespace :annotator do

  def  init_annotator
    require 'bundler/setup'
    # Configure the process for the current cron configuration.
    require_relative '../lib/ncbo_cron'
    config_exists = File.exist?(File.expand_path('../../config/config.rb', __FILE__))
    abort('Please create a config/config.rb file using the config/config.rb.sample as a template') unless config_exists
    require_relative '../config/config'

    annotator = Annotator::Models::NcboAnnotator.new
    cur_inst = annotator.redis_current_instance
    alt_inst = annotator.redis_default_alternate_instance
    [annotator, cur_inst, alt_inst]
  end

  namespace :redis_instance do
    desc 'Get current Annotator redis terms cache prefix'
    task :get do
      annotator, cur_inst, alt_inst = init_annotator
      puts cur_inst
    end

    desc 'Delete Annotator term cache from the alternate instance'
    # use with caution!!! useful for reducing memory/disk footprint
    task :purge_alternate do
      annotator, cur_inst, alt_inst = init_annotator
      puts "Cleared Annotator Redis alternate terms cache #{alt_inst}"
      annotator.delete_term_cache(alt_inst)
    end

    desc 'Swap Annotator Redis term cache instance from primary to alternate'
    task :switch_to_alternate do
      annotator, cur_inst, alt_inst = init_annotator
      annotator.redis_switch_instance
      puts "Annotator Redis terms cache instance has been switched to #{alt_inst}"
    end
  end
end

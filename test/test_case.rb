require 'ontologies_linked_data'
require_relative '../lib/ncbo_cron'
#require_relative '../config/config'

Goo.use_cache = false # Make sure tests don't cache

require 'test/unit'

SOLR_HOST  = ENV.include?('SOLR_HOST')  ? ENV['SOLR_HOST']  : 'localhost'
REDIS_HOST = ENV.include?('REDIS_HOST') ? ENV['REDIS_HOST'] : 'localhost'
REDIS_PORT = ENV.include?('REDIS_PORT') ? ENV['REDIS_PORT'] : 6379

LinkedData.config do |config|
  config.goo_backend_name           = ENV.include?('GOO_BACKEND_NAME') ? ENV['GOO_BACKEND_NAME'] : 'localhost'
  config.goo_port                   = ENV.include?('GOO_PORT')         ? ENV['GOO_PORT']         : 9000
  config.goo_host                   = ENV.include?('GOO_HOST')         ? ENV['GOO_HOST']         : 'localhost'
  config.goo_path_query             = ENV.include?('GOO_PATH_QUERY')   ? ENV['GOO_PATH_QUERY']   : '/sparql/'
  config.goo_path_data              = ENV.include?('GOO_PATH_DATA')    ? ENV['GOO_PATH_DATA']    : '/data/'
  config.goo_path_update            = ENV.include?('GOO_PATH_UPDATE')  ? ENV['GOO_PATH_UPDATE']  : '/update/'
  config.goo_redis_port             = REDIS_PORT.to_i
  config.goo_redis_host             = REDIS_HOST.to_s
  config.http_redis_port            = REDIS_PORT.to_i
  config.http_redis_host            = REDIS_HOST.to_s
  config.search_server_url          = "http://#{SOLR_HOST}:8983/solr/term_search_core1"
  config.property_search_server_url = "http://#{SOLR_HOST}:8983/solr/prop_search_core1"
end
Annotator.config do |config|
  config.annotator_redis_host          = REDIS_HOST.to_s
  config.annotator_redis_port          = REDIS_PORT.to_i
  config.mgrep_host                    = ENV.include?('MGREP_HOST') ? ENV['MGREP_HOST'] : 'localhost'
  config.mgrep_port                    = ENV.include?('MGREP_PORT') ? ENV['MGREP_PORT'] : 55555
  config.mgrep_dictionary_file         = './test/data/dictionary.txt'
end
LinkedData::OntologiesAPI.config do |config|
  config.http_redis_host = REDIS_HOST.to_s
  config.http_redis_port = REDIS_PORT.to_i
end

NcboCron.config do |config|
  config.redis_host = REDIS_HOST.to_s
  config.redis_port = REDIS_PORT.to_i
end

# Check to make sure you want to run if not pointed at localhost
safe_host = Regexp.new(/localhost|-ut|ncbo-dev*|ncbo-unittest*/)
unless LinkedData.settings.goo_host.match(safe_host) &&
       LinkedData.settings.search_server_url.match(safe_host) &&
       NcboCron.settings.redis_host.match(safe_host)
  print '\n\n================================== WARNING ==================================\n'
  print '** TESTS CAN BE DESTRUCTIVE -- YOU ARE POINTING TO A POTENTIAL PRODUCTION/STAGE SERVER **\n'
  print 'Servers:\n'
  print "triplestore -- #{LinkedData.settings.goo_host}\n"
  print "search -- #{LinkedData.settings.search_server_url}\n"
  print "redis -- #{NcboCron.settings.redis_host}\n"
  print "Type 'y' to continue: "
  $stdout.flush
  confirm = $stdin.gets
  abort('Canceling tests...\n\n') unless confirm.strip == 'y'
  print 'Running tests...'
  $stdout.flush
end

require 'minitest/unit'
MiniTest::Unit.autorun

class CronUnit < MiniTest::Unit
  def count_pattern(pattern)
    q = "SELECT (count(DISTINCT ?s) as ?c) WHERE { #{pattern} }"
    rs = Goo.sparql_query_client.query(q)
    rs.each_solution do |sol|
      return sol[:c].object
    end
    return 0
  end

  def backend_4s_delete
    if count_pattern("?s ?p ?o") < 400000
      LinkedData::Models::Ontology.where.include(:acronym).each do |o|
        query = "submissionAcronym:#{o.acronym}"
        LinkedData::Models::Ontology.unindexByQuery(query)
      end
      LinkedData::Models::Ontology.indexCommit
      Goo.sparql_update_client.update('DELETE {?s ?p ?o } WHERE { ?s ?p ?o }')
      LinkedData::Models::SubmissionStatus.init_enum
      LinkedData::Models::OntologyFormat.init_enum
      LinkedData::Models::OntologyType.init_enum
      LinkedData::Models::Users::Role.init_enum
      LinkedData::Models::Users::NotificationType.init_enum
    else
      raise Exception, 'Too many triples in KB, does not seem right to run tests'
    end
  end

  def before_suites
    # code to run before the very first test
  end

  def after_suites
    # code to run after the very last test
  end

  def _run_suites(suites, type)
    before_suites
    super(suites, type)
  ensure
    after_suites
  end

  def _run_suite(suite, type)
    backend_4s_delete
    suite.before_suite if suite.respond_to?(:before_suite)
    super(suite, type)
  rescue Exception => e
    puts e.message
    puts e.backtrace.join("\n\t")
    puts 'Traced from:'
    raise e
  ensure
    backend_4s_delete
    suite.after_suite if suite.respond_to?(:after_suite)
  end
end
MiniTest::Unit.runner = CronUnit.new

##
# Base test class. Put shared test methods or setup here.
class TestCase < MiniTest::Unit::TestCase
end

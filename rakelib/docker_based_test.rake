# Rake tasks for running unit tests with backend services running as docker containers

desc 'Run unit tests with docker based backend'
namespace :test do
  namespace :docker do
    task :up do
      system("docker compose up -d") || abort("Unable to start docker containers")
      unless system("curl -sf  http://localhost:8983/solr  || exit 1")
        printf("waiting for Solr container to initialize")
        sec = 0
        until system("curl -sf http://localhost:8983/solr || exit 1") do
          sleep(1)
          printf(".")
          sec += 1
          if sec > 30
            abort("  Solr container hasn't initialized properly")
          end
        end
        printf("\n")
      end
    end
    task :down do
      #system("docker compose --profile fs --profile ag stop")
      #system("docker compose --profile fs --profile ag kill")
    end
    desc "run tests with docker AG backend"
    task :ag do
      ENV["GOO_BACKEND_NAME"]="allegrograph"
      ENV["GOO_PORT"]="10035"
      ENV["GOO_PATH_QUERY"]="/repositories/ontoportal_test"
      ENV["GOO_PATH_DATA"]="/repositories/ontoportal_test/statements"
      ENV["GOO_PATH_UPDATE"]="/repositories/ontoportal_test/statements"
      ENV["COMPOSE_PROFILES"]="ag"
      Rake::Task["test:docker:up"].invoke
      # AG takes some time to start and create databases/accounts
      test_connection("AllegroGraph", "http://127.0.0.1:10035/repositories/ontoportal_test/status")      
      Rake::Task["test"].invoke
      Rake::Task["test:docker:down"].invoke
    end

    desc "run tests with docker 4store backend"
    task :fs do
      ENV["GOO_BACKEND_NAME"]="4store"
      ENV["GOO_PORT"]="9000"
      ENV["GOO_PATH_QUERY"]="/sparql/"
      ENV["GOO_PATH_DATA"]="/data/"
      ENV["GOO_PATH_UPDATE"]="/update/"
      ENV["COMPOSE_PROFILES"]="fs"
      Rake::Task["test:docker:up"].invoke
      test_connection("4store", "http://localhost:9000/status/")
      Rake::Task["test"].invoke
      Rake::Task["test:docker:down"].invoke
    end

    desc "run tests with docker Virtuoso backend"
    task :vo do
      ENV["GOO_BACKEND_NAME"]="virtuoso"
      ENV["GOO_PORT"]="8890"
      ENV["GOO_PATH_QUERY"]="/sparql"
      ENV["GOO_PATH_DATA"]="/sparql"
      ENV["GOO_PATH_UPDATE"]="/sparql"
      ENV["COMPOSE_PROFILES"]="virtuoso"
      Rake::Task["test:docker:up"].invoke
      test_connection("Virtuoso", "http://localhost:8890/sparql")
      Rake::Task["test"].invoke
      Rake::Task["test:docker:down"].invoke
    end


    desc "run tests with docker GraphDb backend"
    task :gb do
      ENV["GOO_BACKEND_NAME"]="graphdb"
      ENV["GOO_PORT"]="7200"
      ENV["GOO_PATH_QUERY"]="/repositories/ontoportal"
      ENV["GOO_PATH_DATA"]="/repositories/ontoportal/statements"
      ENV["GOO_PATH_UPDATE"]="/repositories/ontoportal/statements"
      ENV["COMPOSE_PROFILES"]="gb"
      Rake::Task["test:docker:up"].invoke

      #system("docker compose cp ./test/data/graphdb-repo-config.ttl graphdb:/opt/graphdb/dist/configs/templates/graphdb-repo-config.ttl")
      #system("docker compose cp ./test/data/graphdb-test-load.nt graphdb:/opt/graphdb/dist/configs/templates/graphdb-test-load.nt")
      #system('docker compose exec graphdb sh -c "importrdf load -f -c /opt/graphdb/dist/configs/templates/graphdb-repo-config.ttl -m parallel /opt/graphdb/dist/configs/templates/graphdb-test-load.nt ;"')
      test_connection("Graphdb", "http://localhost:7200/repositories")
      Rake::Task["test"].invoke
      Rake::Task["test:docker:down"].invoke
    end

    private
    
    def test_connection(backend_name, url)
      # TODO: replace system curl command with native ruby code
      command = "curl -sf -o /dev/null #{url} || exit 1"
      if backend_name == "AllegroGraph"
              command = "curl -sf #{url} | grep -iqE '(^running|^lingering)' || exit 1"
      end
      unless system(command)
        printf("waiting for #{backend_name} container to initialize")
        sec = 0
        until system(command) do
          sleep(1)
          printf(".")
          sec += 1
          if sec > 30
            system("docker compose logs #{backend_name}")
            abort("  #{backend_name} container hasn't initialized properly")
          end
        end
      end
    end

  end
end

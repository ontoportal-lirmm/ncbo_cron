#!/usr/bin/env bash
profile=$1
acronym=$2
from_apikey=$3
import_from_api=$4
set -e

if [ -z "$import_from_api" ]; then
  import_from_api=https://data.stageportal.lirmm.fr
fi

if [ -z "$from_apikey" ]; then
  from_apikey="1de0a270-29c5-4dda-b043-7c3580628cd5"
fi

# Documentation:
# The below script is used to start the OntoPortal services with a specific backend type.
# The script takes two arguments: acronym and profile.
# The acronym is the name of the ontology to be imported.
# The profile is the type of backend to be used.

if [ -z "$profile" ]; then
  echo "Usage: $0 <acronym> <profile>"
  exit 1
fi

BACKEND_TYPE=$profile
if [ "$BACKEND_TYPE" == "ag" ]; then
  # AllegroGraph backend
  export GOO_BACKEND_NAME="allegrograph"
  export GOO_PORT="10035"
  export GOO_PATH_QUERY="/repositories/ontoportal_test"
  export GOO_PATH_DATA="/repositories/ontoportal_test/statements"
  export GOO_PATH_UPDATE="/repositories/ontoportal_test/statements"
  export COMPOSE_PROFILES="ag"

elif [ "$BACKEND_TYPE" == "fs" ]; then
  # 4store backend
  export GOO_PORT="9000"
  export COMPOSE_PROFILES="fs"

elif [ "$BACKEND_TYPE" == "vo" ]; then
  # Virtuoso backend
  export GOO_BACKEND_NAME="virtuoso"
  export GOO_PORT="8890"
  export GOO_PATH_QUERY="/sparql"
  export GOO_PATH_DATA="/sparql"
  export GOO_PATH_UPDATE="/sparql"
  export COMPOSE_PROFILES="vo"

elif [ "$BACKEND_TYPE" == "gb" ]; then
  # Graphdb backend
  export GOO_BACKEND_NAME="graphdb"
  export GOO_PORT="7200"
  export GOO_PATH_QUERY="/repositories/ontoportal"
  export GOO_PATH_DATA="/repositories/ontoportal/statements"
  export GOO_PATH_UPDATE="/repositories/ontoportal/statements"
else
  echo "Error: Unknown backend type $profile. Please set BACKEND_TYPE to 'ag', 'fs', or 'vo'."
fi

echo "###########################################################################"
echo "Stop and remove all containers, networks, and volumes and start fresh"
docker compose --profile fs --profile vo --profile gb --profile ag down  --volumes --remove-orphans && docker compose --profile "$profile" up -d

echo "Waiting for all Docker services to start..."

while true; do
    # Get the status of all containers
    container_status=$(docker compose --profile "$profile" ps -a --format '{{.Names}} {{.State}}')

    all_running=true
    while read -r container state; do
        if [ "$state" != "running" ] && [ "$state" != "exited" ]; then
            all_running=false
            break
        fi
    done <<< "$container_status"

    # If all containers are running, exit the loop
    if [ "$all_running" = true ]; then
        echo "All containers are running!"
        break
    fi

    # Wait before checking again
    sleep 2
done

if [ -z "$acronym" ]; then
  exit 0
fi

echo "###########################################################################"
echo "Create a new user and make it an admin"
bundle exec rake user:create[admin,admin@nodomain.org,password]
bundle exec rake user:adminify[admin]
echo "###########################################################################"
echo "Create a new ontology $acronym and import it from a remote server"
bin/ncbo_ontology_import --admin-user admin -o "$acronym" --from "$import_from_api" --from-apikey "$from_apikey"

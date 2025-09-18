#!/usr/bin/env bash
set -e

# Default values
import_from_api="https://data.agroportal.lirmm.fr"
from_apikey="1de0a270-29c5-4dda-b043-7c3580628cd5"
BACKEND_TYPE="vo"
ontology=""
process_ontology=false

# Usage function
usage() {
  echo "Usage: $0 [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --api-url URL      : API URL to import from (default: https://data.agroportal.lirmm.fr)"
  echo "  --api-key KEY      : API key for import (default: 1de0a270-29c5-4dda-b043-7c3580628cd5)"
  echo "  --backend TYPE     : Backend type: ag (AllegroGraph), fs (4store), vo (Virtuoso), gb (GraphDB) (default: vo)"
  echo "  --ontology ONT : Ontology acronym to import"
  echo "  --process      : process the ontology after import"
  echo "  -h, --help         : Show this help message"
  exit 1
}

# Parse command line options
while [[ $# -gt 0 ]]; do
  case $1 in
    --api-url)
      import_from_api="$2"
      shift 2
      ;;
    --api-key)
      from_apikey="$2"
      shift 2
      ;;
    --backend)
      BACKEND_TYPE="$2"
      shift 2
      ;;
    --ontology)
      ontology="$2"
      shift 2
      ;;
    --process)
      process_ontology=true
      shift 1
      ;;
    -h|--help)
      usage
      ;;
    --*|-*)
      echo "Error: Unknown option $1" >&2
      usage
      ;;
    *)
      echo "Error: Positional arguments are not supported. Use options instead." >&2
      echo "       See --help for usage information." >&2
      exit 1
      ;;
  esac
done

# Backend configuration
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
  export COMPOSE_PROFILES="gb"
else
  echo "Error: Unknown backend type $BACKEND_TYPE. Please set backend to 'ag', 'fs', 'vo', or 'gb'." >&2
  exit 1
fi

echo "[+] Running with BACKEND_TYPE $BACKEND_TYPE. Ontology to import: ${ontology:-none} from $import_from_api with API key $from_apikey"

echo "[+] Stop and remove all containers, networks, and volumes and start fresh"
docker compose --profile fs --profile vo --profile gb --profile ag down --volumes --remove-orphans && docker compose --profile "$BACKEND_TYPE" up -d

echo "Waiting for all Docker services to start..."

while true; do
    # Get the status of all containers
    container_status=$(docker compose --profile "$BACKEND_TYPE" ps -a --format '{{.Names}} {{.State}}')

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


echo "[+] Create a new user and make it an admin"
bundle exec rake user:create[admin,admin@nodomain.org,password]
bundle exec rake user:adminify[admin]


if [ -n "$ontology" ]; then
  echo "[+] Create a new ontology $ontology and import it from a remote server"
  bin/ncbo_ontology_import --admin-user admin -o "$ontology" --from "$import_from_api" --from-apikey "$from_apikey"
else
  echo "[+] Services started successfully. No ontology specified for import."
  exit 0
fi

if [ "$process_ontology" = true ]; then
  echo "[+] Processing ontology $ontology"
  bin/ncbo_ontology_process -o "$ontology"
  echo "[+] Ignoring the error of ontologies_report.json"
else
  echo "[+] Skipping processing of ontology $ontology"
fi

echo "[+] Finished setting up the OntoPortal services with backend type $BACKEND_TYPE"

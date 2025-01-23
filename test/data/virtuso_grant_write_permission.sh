#!/bin/bash

# Virtuoso database connection credentials
DB_PORT=1111
DB_USER="dba"
DB_PASS="dba"
VIRTUOSO_DIR=$1

if [ "$#" -ne 1 ]; then
  VIRTUOSO_DIR="/opt/virtuoso-opensource/"
fi
# Connect to Virtuoso using isql and grant EXECUTE permission
echo "-- Granting EXECUTE permission on DB.DBA.SPARQL_INSERT_DICT_CONTENT..."

$VIRTUOSO_DIR/bin/isql $DB_PORT $DB_USER $DB_PASS <<EOF
GRANT EXECUTE ON DB.DBA.SPARQL_INSERT_DICT_CONTENT TO "SPARQL";
EOF

# Check if the operation was successful
if [ $? -eq 0 ]; then
  echo "Permission granted successfully."
else
  echo "Failed to grant permission."
  exit 1
fi

# Optionally, grant the SPARQL_UPDATE role to the user for more permissions
echo "-- Granting SPARQL_UPDATE role to 'SPARQL'..."
$VIRTUOSO_DIR/bin/isql $DB_PORT $DB_USER $DB_PASS <<EOF
GRANT SPARQL_UPDATE TO "SPARQL";
EOF

if [ $? -eq 0 ]; then
  echo "SPARQL_UPDATE role granted successfully."
else
  echo "Failed to grant SPARQL_UPDATE role."
  exit 1
fi

echo "-- Granting WRITE permission on all graphs to SPARQL user..."

$VIRTUOSO_DIR/bin/isql $DB_PORT $DB_USER $DB_PASS <<EOF
DB.DBA.RDF_DEFAULT_USER_PERMS_SET ('nobody', 7);
EOF

# Check if the operation was successful
if [ $? -eq 0 ]; then
  echo "WRITE permission granted successfully to SPARQL on all graphs."
else
  echo "Failed to grant WRITE permission."
  exit 1
fi

# Restart Virtuoso to apply changes
echo "-- Restarting Virtuoso server to apply changes..."
$VIRTUOSO_DIR/bin/virtuoso-t +wait

echo "Permission changes applied and Virtuoso restarted."

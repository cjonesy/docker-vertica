#!/bin/bash
set -e

# Function to shut down Vertica gracefully
function shut_down() {
  echo "Shutting Down Vertica"
  gosu dbadmin /opt/vertica/bin/admintools -t stop_db -d docker -i
  exit
}

# Ensure Vertica gets shutdown correctly
trap "shut_down" SIGKILL SIGTERM SIGHUP SIGINT EXIT

# Set dbadmin as the owner of our data
chown -R dbadmin:verticadba "$VERTICADATA"

# If no data exists, create the database, otherwise just start the db
if [ -z "$(ls -A "$VERTICADATA")" ]; then
  echo "Creating database"
  gosu dbadmin /opt/vertica/bin/admintools -t drop_db -d docker
  gosu dbadmin /opt/vertica/bin/admintools -t create_db -s localhost --skip-fs-checks -d docker -c /home/dbadmin/docker/catalog -D /home/dbadmin/docker/data
else
  gosu dbadmin /opt/vertica/bin/admintools -t start_db -d docker -i
fi

echo "Vertica is now running"

# If sql files were provided, run them to bootstrap the database
if [ -d /objects ]; then
    echo "Creating objects..."
    find /objects/*.sql -exec /opt/vertica/bin/vsql -h localhost -U dbadmin -d docker -f {} \;
else
    echo "No object scripts found, proceeding with an empty database."
fi

while true; do
  sleep 1
done


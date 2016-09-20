# Docker Image for Vertica

Dockerfile to build image of Vertica Community Edition.

The image creates a database called docker, with a blank dbadmin password.

## Usage:

Download the Vertica deb from https://my.vertica.com and put it in this folder.
Then run:
```bash
docker build -t cjonesy/docker-vertica .
```

### To run without a persistent datastore
```bash
docker run -P  cjonesy/docker-vertica
```

### To run with a persistent datastore
```bash
docker run -P -v /path/to/vertica_data:/home/dbadmin/docker cjonesy/docker-vertica
```

### To bootstrap the new database, put sql files in a directory and add objects volume:
```bash
docker run -P -v /path/to/sql_scripts:/objects cjonesy/docker-vertica
```
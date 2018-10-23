# GOB-Documentation

GOB overall project documentation

## Local Development

The preferred way to work on GOB is to have all GOB projects in a separate GOB directory.
Within this directory the GOB projects can be instantiated.

```bash
mkdir gob
cd gob

# GOB Documentation (this project)
git clone git@github.com:Amsterdam/GOB-Documentation.git

# GOB Workflow (the workflow router)
git clone git@github.com:Amsterdam/GOB-Workflow.git

# GOB Import (the import of the GOB sources)
git clone git@github.com:Amsterdam/GOB-Import-Client-Template.git

# GOB Upload (the upload of imported data into GOB)
git clone git@github.com:Amsterdam/GOB-Upload.git

# GOB API (the exposure of GOB data via an API)
git clone git@github.com:Amsterdam/GOB-API.git

# GOB Export (the construction of GOB "products")
git clone git@github.com:Amsterdam/GOB-Export.git

# GOB Management API (GOB management overview and control - API)
git clone git@github.com:Amsterdam/GOB-API.git

# GOB Management Frontenc (GOB management overview and control - frontend)
git clone git@github.com:Amsterdam/GOB-Management-Frontend.git

```

Follow the instructions in each project to build and start each project.

## Running GOB

GOB requires an infrastructure with a:
- Message Broker
- Management Database
- Database
- Shared network and storage

### Message Broker and Management Database

To start a message broker and management database instance
follow the instructions in the GOB Workflow project.

```bash
# Message broker and management database
cd gob/GOB-Workflow
docker-compose up rabbitmq &
docker-compose up management_database &

```

### Storage

To start a database instance
follow the instructions in the GOB Upload project

```bash
# Database
cd gob/GOB-Upload
docker-compose up database &
```

### Shared network and storage

```bash
docker network create gob-network
docker volume create gob-volume --opt device=/tmp --opt o=bind

```

## Startup

The message broker and databases are only used for local development.

The Datapunt infrastructure hosts its own instances.

Now start the workflow and upload components:

```bash
# Workflow manager
cd gob/GOB-Workflow
source venv/bin/activate
cd src
python -m gobworkflow

```

```bash
# Upload client
cd gob/GOB-Upload
source venv/bin/activate
cd src
python -m gobuploadservice

```

The basic infrastructure is now available.

To start an import:

```bash
# Import
cd gob/GOB-Import-Client-Template/
source venv/bin/activate
cd src
python -m gobimportclient example/meetbouten.json

```

## Branches

The master and develop branches in each project are protected against direct updates.
Updates to these branches is uniquely by means of pull requests.
Pull request are rebased onto the target branch.

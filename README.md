# GOB-Documentation

GOB overall project documentation

## Environment

The preferred way to work on GOB is to have all GOB projects in a separate GOB directory.
Within this directory the GOB projects can be instantiated.

```bash
mkdir gob
cd gob

# GOB Documentation (this project)
git clone https://github.com/Amsterdam/GOB-Documentation.git

# GOB Infra (GOB infrastructure components)
git clone https://github.com/Amsterdam/GOB-Infra.git

# GOB Core (GOB shared code)
git clone https://github.com/Amsterdam/GOB-Core.git

# GOB Workflow (the workflow router)
git clone https://github.com/Amsterdam/GOB-Workflow.git

# GOB Prepare (preparation of data before import)
git clone https://github.com/Amsterdam/GOB-Prepare.git

# GOB Import (the import of the GOB sources)
git clone https://github.com/Amsterdam/GOB-Import.git

# GOB Upload (the upload of imported data into GOB)
git clone https://github.com/Amsterdam/GOB-Upload.git

# GOB API (the exposure of GOB data via an API)
git clone https://github.com/Amsterdam/GOB-API.git

# GOB Export (the construction of GOB "products")
git clone https://github.com/Amsterdam/GOB-Export.git

# GOB Management API (GOB management overview and control - API)
git clone https://github.com/Amsterdam/GOB-Management.git

# GOB Management Frontend (GOB management overview and control - frontend)
git clone https://github.com/Amsterdam/GOB-Management-Frontend.git

```

## Quick start

### Requirements

* docker-compose >= 1.17
* docker ce >= 18.03

### startall.sh

The startall.sh script in the scripts directory initializes and starts all required GOB components

```bash
cd GOB-Documentation/scripts/docker
bash startall.sh
cd ../..

```

### e2e.sh

#### Requirements

* curl >= 7.0

After all components have started you can test if GOB is running correctly by using the e2e.sh script

```bash
cd GOB-Documentation/scripts/docker
bash e2e.sh
cd ../..
```

## Local Development

Follow the instructions in each project to build and start each project.

## Startup

GOB requires an infrastructure with a:
- Shared Network and Shared Volume
- Message Broker and Databases

### Shared Network and Shared Volume

```bash
docker network create gob-network
docker volume create gob-volume --opt device=/tmp --opt o=bind
```
### Message Broker and Databases

```bash
# Message broker and databases
cd GOB-Infra
docker-compose up &
cd ..

```

For more information see the instructions in the GOB Infra project.

## Branches

The master and develop branches in each project are protected against direct updates.
Updates to these branches is uniquely by means of pull requests.
Pull request are rebased onto the target branch.

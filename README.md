# GOB-Documentation

GOB overall project documentation

## Local Development

The preferred way to work on GOB is to have all GOB projects in a separate GOB directory.
Within this directory the GOB projects can be instantiated.

```bash
mkdir gob
cd gob

# GOB Documentation
git clone git@github.com:Amsterdam/GOB-Documentation.git

# GOB Workflow
git clone git@github.com:Amsterdam/GOB-Workflow.git

# GOB Import
git clone git@github.com:Amsterdam/GOB-Import-Client-Template.git

# GOB Upload
git clone git@github.com:Amsterdam/GOB-Upload.git


```

Follow the instructions in each project to build and start each project.

In order to communicate with other components you need at least a running message broker container.
To access the storage you need a running storage container.

### Message Broker

To start a message broker instance follow the instructions in the GOB Workflow project.

### Storage

To start a database instance follow the instructions in the GOB Upload porject

### Startup

Once every project has been build and initialized the startup for GOB will be:

```bash
# Message broker
cd gob/GOB-Workflow
docker-compose up rabbitmq &

```

```bash
# Database
cd gob/GOB-Upload
docker-compose up database &

```

The message broker and database are only used for local development.

The Datapunt infrastructure hosts its own instances.

These global instances are used when running GOB outside the local development environment.

Now start the workflow and upload components:

```bash
# Workflow manager
cd gob/GOB-Workflow
source venv/bin/activate

cd src
export MESSAGE_BROKER_ADDRESS=localhost
python -m gobworkflow

```


```bash
# Upload client
cd gob/GOB-Upload
source venv/bin/activate

cd src
export MESSAGE_BROKER_ADDRESS=localhost
python -m gobuploadservice

```

The basic infrastructure is now available.

To start an import:

```bash
# Import
cd gob/GOB-Import-Client-Template/
source venv/bin/activate

cd src
export MESSAGE_BROKER_ADDRESS=localhost
python -m gobimportclient example/meetbouten.json

```

## Branches

The master and develop branches in each project are protected against direct updates.
Updates to these branches is uniquely by means of pull requests.
Pull request are rebased onto the target branch.

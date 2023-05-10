# GOB-Documentation

GOB overall project documentation.

## Environment

The preferred way to work on GOB is to have all GOB projects in a separate `gob` directory.
Within this directory the GOB projects can be instantiated.

```bash
mkdir gob
cd gob

# Use this if you prefer to clone via SSH:
GITHUB=git@github.com:
# Uncomment this if you prefer to clone via HTTPS:
# GITHUB=https://github.com

# GOB Documentation (this project)
git clone $GITHUB/Amsterdam/GOB-Documentation.git

# GOB Infra (GOB infrastructure components)
git clone $GITHUB/Amsterdam/GOB-Infra.git

# GOB Core (GOB shared code)
git clone $GITHUB/Amsterdam/GOB-Core.git

# GOB Config (GOB shared configuration)
git clone $GITHUB/Amsterdam/GOB-Config.git

# GOB Workflow (the workflow router)
git clone $GITHUB/Amsterdam/GOB-Workflow.git

# GOB Prepare (preparation of data before import)
git clone $GITHUB/Amsterdam/GOB-Prepare.git

# GOB BagExtract (the bag extract of the GOB sources)
git clone $GITHUB/Amsterdam/GOB-BagExtract.git

# GOB Import (the import of the GOB sources)
git clone $GITHUB/Amsterdam/GOB-Import.git

# GOB Upload (the upload of imported data into GOB)
git clone $GITHUB/Amsterdam/GOB-Upload.git

# GOB API (the exposure of GOB data via an API)
git clone $GITHUB/Amsterdam/GOB-API.git

# GOB Export (the construction of GOB "products")
git clone $GITHUB/Amsterdam/GOB-Export.git

# GOB Distribute (distribution of GOB "products")
git clone $GITHUB/Amsterdam/GOB-Distribute.git

# GOB Test (GOB end-2-end tests)
git clone $GITHUB/Amsterdam/GOB-Test.git

# GOB Message (receives mutation or signal messages from external systems)
git clone $GITHUB/Amsterdam/GOB-Message.git

# GOB StUF (GOB StUF provides for StUF access)
git clone $GITHUB/Amsterdam/GOB-StUF.git

# GOB Management API (GOB management overview and control - API)
git clone $GITHUB/Amsterdam/GOB-Management.git

# GOB Management Frontend (GOB management overview and control - frontend)
git clone $GITHUB/Amsterdam/GOB-Management-Frontend.git

# GOB EventConsumer (Consumes events to update the RefDB)
git clone $GITHUB/Amsterdam/GOB-EventConsumer.git

# GOB EventProducer (Reads GOB events, transforms them to a generic format and sends these to a different exchange)
git clone $GITHUB/Amsterdam/GOB-EventProducer.git

```

## Quick start

### Requirements

* docker compose >= 1.25
* Docker CE >= 18.09
* Python 3.9

### Start GOB

The `gob.sh` script in the scripts directory can be used to initialize and start all required GOB components:

```bash
./GOB-Documentation/scripts/docker/gob.sh start
```

When the script has finished successfully you can start [GOB Management](http://github.com/Amsterdam/GOB-Management) in your browser at: `http://localhost:8080`.

### Show GOB components

Show the status of the GOB components:

```bash
./GOB-Documentation/scripts/docker/gob.sh ls
```

### Stop GOB

Stop the GOB components with the `gob.sh` script:

```bash
./GOB-Documentation/scripts/docker/gob.sh stop
```

### End-to-End tests

The End-to-End tests can be found in the [GOB-Test](https://github.com/Amsterdam/GOB-Test) repo.

## Local Development

Follow the instructions in each project to build and start each project.

To start working an a specific GOB module you can stop the docker container and
run only the specific module that you want to change locally.

If for instance you would like to work on [GOB-Export](https://github.com/Amsterdam/GOB-Export) use:

```bash
docker stop gobexport
cd GOB-Export
# and then follow the steps to start gobexport locally
```

This works for most modules with the exception of:
- [GOB-Import](https://github.com/Amsterdam/GOB-Import) and [GOB-Upload](https://github.com/Amsterdam/GOB-Upload), these modules should run either both locally or both inside a docker.

## Manual Startup

All required setup is done by the `gob.sh start` script as described in the previous paragraph.

If you want to setup the GOB infrastructure manually you can follow the steps as described in the [GOB-Infra](https://github.com/Amsterdam/GOB-Infra) project.

## Branches and Pull Requests

The master and develop branches in each project are protected against direct updates.

Updates to these branches is uniquely by means of pull requests.

Pull request onto the develop branch are **rebased**.

Pull request from develop onto the master branch are **merged**.

Code coverage requirements of a project can only be set the higher values.
Pull requests that lower the code coverage will be rejected.

## Configuration

GOB is a data driven application and has no hardcoded knowledge of the data it is processing.

The exceptions are GOB-Import and GOB-Export.
They are the input and output of GOB and are responsable for the conversion of data to and from GOB format.
Beside the configurations also some hardcoded knowledge of the data may exist in these modules.

The main configuration items are:

- GOB Data
  - [GOB Data model](https://github.com/Amsterdam/GOB-Core/blob/master/gobcore/model/gobmodel.json)
  - [GOB Data relations](https://github.com/Amsterdam/GOB-Core/blob/master/gobcore/sources/gobsources.json)
- Import
  - [GOB Data Preparation definitions](https://github.com/Amsterdam/GOB-Prepare/tree/develop/src/data)
  - [GOB Data Import definitions](https://github.com/Amsterdam/GOB-Config/tree/master/gobconfig/import_/data)
- Export
  - [GOB Views (custom data definitions used by API and Export)](https://github.com/Amsterdam/GOB-Core/blob/master/gobcore/views)
  - [GOB Export definitions](https://github.com/Amsterdam/GOB-Export/tree/develop/src/gobexport/exporter/config)

Other interesting documentation:

- [GOB Basic Principles](https://github.com/Amsterdam/GOB-Documentation/blob/master/docs/basic_principles.md)
- [GOB Security](https://github.com/Amsterdam/GOB-Documentation/blob/master/docs/security.md)
- [GOB Id's](https://github.com/Amsterdam/GOB-Core/blob/master/gobcore/model/README.md)
- [GOB Event handling](https://github.com/Amsterdam/GOB-Upload/blob/develop/src/gobupload/storage/README.md)
- [GOB Relations](https://github.com/Amsterdam/GOB-Upload/blob/develop/src/gobupload/relate/README.md)
- [GOB Dump to other database](https://github.com/Amsterdam/GOB-API/tree/develop/src/gobapi/dump)
- [GOB Authentication and Authorization](https://github.com/Amsterdam/GOB-API/blob/develop/src/gobapi/auth/README.md)

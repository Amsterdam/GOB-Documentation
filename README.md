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

### start GOB

The gob.sh script in the scripts directory can be used to initialize and start all required GOB components

```bash
cd GOB-Documentation/scripts/docker
bash gob.sh start
cd ../../..

```

When the script has finished successfully you can start GOB Management in your browser at: http://localhost:8080

### e2e.sh

#### Requirements

* curl >= 7.0

After all components have started you can test if GOB is running correctly by using the e2e.sh script

```bash
cd GOB-Documentation/scripts/docker
bash e2e.sh
cd ../../..
```

The test results are shown on stdout, the jobs are visible in GOB Management in your browser.

## Local Development

Follow the instructions in each project to build and start each project.

To start working an a specific GOB module you can stop the docker container and
run only the specific module that you want to change locally.

If for instance you would like to work on GOB-Export use:

```bash
docker stop gobexport
cd GOB-Export
# and then follow the steps to start gobexport locally
```

This works for most modules with the exception of:
- GOB-Import and GOB-Upload, these modules should run either both locally or both inside a docker.

## Manual Startup

All required setup is done by the "gob.sh start" script as described in the previous paragraph.

If you want to setup the GOB infrastructure manually you can follow the steps as described in the GOB-Infra project.

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
  - [GOB Data Import definitions](https://github.com/Amsterdam/GOB-Import/tree/develop/src/data)
- Export
  - [GOB Views (custom data definitions used by API and Export)](https://github.com/Amsterdam/GOB-Core/blob/master/gobcore/views/gobviews.json)
  - [GOB Export definitions](https://github.com/Amsterdam/GOB-Export/tree/develop/src/gobexport/exporter/config)

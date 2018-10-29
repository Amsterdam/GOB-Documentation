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
git clone git@github.com:Amsterdam/GOB-Import.git

# GOB Upload (the upload of imported data into GOB)
git clone git@github.com:Amsterdam/GOB-Upload.git

# GOB API (the exposure of GOB data via an API)
git clone git@github.com:Amsterdam/GOB-API.git

# GOB Export (the construction of GOB "products")
git clone git@github.com:Amsterdam/GOB-Export.git

# GOB Management API (GOB management overview and control - API)
git clone git@github.com:Amsterdam/GOB-Management.git

# GOB Management Frontend (GOB management overview and control - frontend)
git clone git@github.com:Amsterdam/GOB-Management-Frontend.git

```

Follow the instructions in each project to build and start each project.

## Running GOB

## Startup

GOB requires an infrastructure with a:
- Shared network and volume
- Message Broker
- Database
- Management Database

To build and start the infrastructure
follow the instructions in the [GOB Infra project](https://github.com/Amsterdam/GOB-Infra)

When the infrastructure has been setup the other GOB components can be started.

A minimal configuration requires the
**[workflow](https://github.com/Amsterdam/GOB-Workflow)**
and
**[upload](https://github.com/Amsterdam/GOB-Upload)**
components.

A (small) **[import](https://github.com/Amsterdam/GOB-Import)**
can be run to test the configuration.

## Branches

The master and develop branches in each project are protected against direct updates.
Updates to these branches is uniquely by means of pull requests.
Pull request are rebased onto the target branch.

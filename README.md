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

# GOB Message Broker
git clone git@github.com:Amsterdam/GOB-Message-Broker.git

# GOB Storage
git clone git@github.com:Amsterdam/GOB-Storage.git

# GOB ...
git@github.com:Amsterdam/GOB-...

```

Follow the instructions in each project to build and start each project.

In order to communicate with other components you need at least a running message broker container.
To access the storage you need a running storage container.

## Branches

The master and develop branches in each project are protected against direct updates.
Updates to these branches is uniquely by means of pull requests.
Pull request are rebased onto the target branch.

# GOB Basic Principles

GOB has been designed on the basis of a set of design and architecture principles.
These principles are explained in the next paragraphs.

## Event Sourcing

The main reason for using event sourcing is data governance and more specifically data accountability.

Event Sourcing ensures that all changes are stored as a sequence of events.
Not just can we query these events, we can also use the event log to reconstruct past states.

This leads to a number of advantages:

- Complete Rebuild  
We can discard the application state completely and rebuild it by re-running the events from the event log on an empty database.

- Temporal Query  
We can determine the application state at any point in time.
Notionally we do this by starting with a blank state and rerunning the events up to a particular time or event.
We can take this further by considering multiple time-lines (analogous to branching in a version control system).

- Event Replay  
If we find a past event was incorrect, we can compute the consequences by reversing it and later events
and then replaying the new event and later events.

Every state of every entity and relation is the sum of events and each event tells:
- what has happened
- when it happened
- by which application

Event Sourcing is a well known and proven technology that originates from accountancy software
and version control systems.

## Mapping onto a Domain Model, generic processing

Data that is processed by GOB is structured data.

The definition of the data is registered in the GOB-Core repository (gobcore/model).
This is a simple json file that describes which catalogs and collections are handled by GOB.

The model is a direct representation of Stelselpedia (https://www.amsterdam.nl/stelselpedia/)

The import of data into GOB is by means of mapping definitions.
A mapping definition defines how the imported data can be translated into GOB format.

Examples of mappings can be found in the GOB-Import repository (src/data)

The further handling of data is completely data driven and agnostic as to the type of data that is handled.

Only in the GOB-Export repository data is again handled and interpreted on the basis of its type.
In between GOB-Import and GOB-Export data is anonymous and only known in terms of its metadata definition.

## Separation of concerns

Processes like importing data, exposing data via an API, exporting data are independent of each other
and organized in separate repositories.

Schematically this looks like:

![GOB Global Overview](./GOB%20global%20overview.png "GOB Global Overview")

This results in relatively small repositories that can be maintained or even replaced without affecting
other repositories.

The repositories are:
- Import  
Encapsulates the access to the data (ftp, database, file, ...)  
and the format of the data (maps it to Stelselpedia format)  
Contains conversion and validation logic

- Upload  
Derives events by comparing new data with existing data  
Stores events  
Apply events
Relate datasets
 
- API  
Exposes GOB data via a REST and GraphQL API

- Export  
Uses the API to generate export files.  
The export files are written to an Objectstore container or to local files

- Distribute  
Component that distributes export products to external locations.

- Workflow  
Routes messages  
Collects and stores log messages  
Registers heartbeats
Contains CLI for starting jobs

- Management API    
Exposes the state of GOB, jobs and logging via a GraphQL API endpoint

- Management frontend  
PWA frontend that shows the status of GOB, its jobs and corresponding logging

- Prepare
Used for certain datasets to perform some preprocessing before importing.

- Message  
Receives and processes mutation messages. At this moment for the HR dataset.

- StUF  
Exposes a REST BRP API. Translates the incoming requests to StUF requests, performs a StUF request to the MKS backend
and transforms the response to a REST response.

Supporting repositories are:

- Test  
Contains end-to-end tests that 1. test the GOB functionality from import to export and 2. test the consistency of the
data between the source and the ultimate export (analyse db).

- Core  
Contains shared functionality (such as logging, message broker, type system etc) and the data model

- Config  
Contains shared configuration, such as import definitions and data store connections.

- Infra  
Contains the infra to run GOB in a development environment

- Documentation  
This repo

## Extensive testing

Tests are a fundamental part of GOB.
Target is at least 100% code coverage for the unit tests, but testing is considered much more than coverage alone.

Testing includes testing for empty values, lower and upper limits (on, before and at), type errors,
exceptions etcetera.

An elementary end-2-end test is included to test the behavior of GOB across components.

## Message Broker

Communication between GOB modules is implemented by using a message broker.

RabbitMQ has been chosen because of its stable state, large community and quality of documentation.

The implementation in GOB contains a few important items:

- All handling is asynchronous  
The handling of messages can be time consuming.
To prevent RabbitMQ time-outs the main event loop runs independent from the message processing thread.
The event loop maintains the communication with RabbitMQ.

- No prefetching of messages  
Messages are not prefetched. This improves scalability and performance.
Messages do not risk to get queued up after long lasting message processes but will always be directed to the next available process.
As long as no process is available the message stays on the bus.

- Offloading of large messages  
Large messages are offloaded in files. The process that sends the message writes it to a file.
The message that reads the message reads its contents from a file.  
The process of offloading and onloading contents to and from file is completely transparent.
It is implemented in the asynchronous message broker and executed automatically.

## "Eat your own dogfood"

The API's that are provided by GOB are also used to generate export files (GOB Export).

Although it is more efficient to generate the exports directly from the database,
it is considered much more useful to use our own API's.

It is an important quality control measure.
By using our own API's we are able to discover problems and bugs earlier than our customers and 
solve any problems beforehand.

## Versioning

The database, model specifications, mapping definitions and API's are all versioned.
This will allow for new GOB releases that may co-exist with previous releases for a certain duration.
Clients can migrate to new versions of GOB relatively independent from the actual GOB releases.

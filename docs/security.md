# GOB Data Security measures

In the most basic terms, Data Security is the process of keeping data secure
and protected from unauthorized access.

The digital privacy measures that are applied within GOB to avoid unauthorized access have been worked out in a Proof Of Concept.

The goal of the Proof Of Concept is to explain, document, and allow reviews and audits on
the GOB privacy measures before the measures get implemented on real data.

## Proof Of Concept

The Proof of Concept shows the implementation of the GOB privacy measures by using a
small dataset. The dataset is located at Objectstore (Basisinformatie, acceptatie/secure/secure.csv).

The dataset contains examples of strings, numbers and dates that are assumed to be private data
and that should only be visible to users that have adequate permissions.

## Keycloak

The underlying authentication mechanism that is used within Datapunt is Keycloak.

Keycloak is an open source Identity and Access Management solution.
Users authenticate with Keycloak rather than individual applications.
This means that GOB doesn't have to deal with login forms, authenticating users, and storing users.

## Logic

The main implementation of the security measures is within GOB-Core.

Data is secured during import and exposed by the API.
These GOB modules use the logic that is implemented by GOB Core to protect sensitive data.

### Importing (GOB Import)

Within GOB Import the mapping of the demo file onto the corresponding GOB Model has been defined.

[secure.csv mapping](https://github.com/Amsterdam/GOB-Import/blob/6fa79c3e87a61ddc10b785eee8835e6273ce3ffd/src/data/secure.csv.json)

As can be seen in this mapping no knowledge or whatsoever of data security is is registered in the import definition.

Data security is defined in the GOB Model and not in individual import specifications.

#### Data is secured as soon at is received.

The data Reader class, that handles all reading of data of all possible kind of datasources (Oracle, Objecstore, Postgress, ...),
has been extended with extra functionality. 

The data Reader is instantiated with an extra argument; the data import specification.

The data import specification is matched with the GOB model to check for any secure datatypes.
Data with secure datatypes is protected against accidental reading by removing it from the data immediately after it has been read.

This measure prevents that sensitive data gets logged, for example:

_"Adres van mevrouw Jansen (BSN: 201333557) is incorrect"_ 

Sensitive data are removed entirely from the dataset and replaced by a random number that has no relation at all with the real data.

If any quality tests should ever be performed on sensitive data then this tests will have to be performed in a "sandbox"-like environment.
It will be perfectly clear that sensitive data is being checked and accidental logging of this data will be prevented.

Within the import process the data will eventually be converted into GOB data.
Within the GOB type system the existing "from_value" method has been replaced with an new method "from_secure_value".
This method checks data for being sensitive.
When sensitive data is handled, the reference to the real value is used to safely convert and encrypt the sensitive data into GOB data.

### Exporting (GOB API)

Within GOB Core secure datatypes have been added (SecureString, SecureDecimal, SecureDateTime).

Within the API, any access to instances of any of these datatypes is handeld by a dedicated resolver / serializer.

The resolver derives the user information from the Keycloak header (X-Auth-Roles).
The user information is handed over to GOB-Core to check for the required access level.
Only if the user is authorized for the specific value the value can be exposed.

All the checks and eventual decryptions are performed in GOB Core.
By itself, the API will never be able to provide access to sensitive data.

### GOB Core

Within GOB Core the
[demo Model](https://github.com/Amsterdam/GOB-Core/blob/81928c4af735881443347eebb8a3fb6663241dad/gobcore/model/gobmodel.json)
has been defined, as well as
[user roles and authorization levels](https://github.com/Amsterdam/GOB-Core/blob/81928c4af735881443347eebb8a3fb6663241dad/gobcore/secure/config.py)

A secure package has been added to GOB Core to actual implement the security measures.

The main module within this package is crypto.py.
This module contains code to encrypt and decrypt data, as well as to protect sensitive data against accidental logging.

#### Confidence level

As can be seen in the GOB Model specification, sensitive data is assigned a confidence level.
Sensitive data with different confidence levels will be encrypted with different secrets.

#### Secret

When sensitive data is encrypted it will be stored with its confidence level and a key index.
The key index denotes the id of the secret key that has been used to encrypt the data.

The combination of confidence level and key index points to a secret that will be used to encrypt the data.

#### Asymmetrical encryption

It is proposed to use an asymmetric encryption algorithm.
The secrets that are used in GOB Import only allow encryption of sensitive data.
The secrets that are used in GOB API only allow for decryption of sensitive data.

#### Key management

Regular change of keys is an important security measure.

Keys should be changed at regular intervals to limit the possible abuse of any "stolen" secrets.
Their use will be limited to the next key change.

Both the confidence level and the key index can be changed.
This requires decryption with the current confidence level and key index and
encryption with the new confidence level and key index.

Changes of confidence levels and key indexes are most easily, but not necessarily, performed when the database is idle.

#### Storage of sensitive data

Sensitive data is stored within GOB as a JSON structure:

```
   {
        "i": key_index,               # Allows for key change
        "l": confidence_level,        # Some data is more confident that other data
        "v": _encrypt(value, secret)  # The encrypted data
    }
```    

#### Protection of sensitive data by GOB Core

The access to an instance of any secure value is handled by the GOB type system.
A special collection of GOB Types has been introduced: GOB Secure Types.

Sensitive data that is used to instantiate a secure GOB Type is automatically encrypted for the
specified confidence level.

Access to sensitive data is by means of a User instance.
The user instance is checked for having the required authorization and only when this requirement is met the data will be decrypted.

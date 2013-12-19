# Fluctus
[![Code Climate](https://codeclimate.com/github/APTrust/fluctus.png)](https://codeclimate.com/github/APTrust/fluctus)
[![Dependency Status](https://gemnasium.com/APTrust/fluctus.png)](https://gemnasium.com/APTrust/fluctus)

Build Status | Continuous Integration | Code Coverate
--- | --- | ---
Production | [![Build Status (Master)](https://travis-ci.org/APTrust/fluctus.png?branch=master)](https://travis-ci.org/APTrust/fluctus) | [![Coverage Status](https://coveralls.io/repos/APTrust/fluctus/badge.png?branch=master)](https://coveralls.io/r/APTrust/fluctus?branch=master)
Development | [![Build Status (Development)](https://travis-ci.org/APTrust/fluctus.png?branch=develop)](https://travis-ci.org/APTrust/fluctus) | [![Coverage Status](https://coveralls.io/repos/APTrust/fluctus/badge.png?branch=develop)](https://coveralls.io/r/APTrust/fluctus?branch=develop)

## APTrust Admin Console (Hydra Head)

This application aims to use the entire Hydra stack to manage all APTrust interactions with Fedora.  

### Requirements

See 'fluctus/Gemfile' for a full list of current dependencies.

Overall Fluctus targets the following versions or later

* Ruby >= 2.0.0
* Rails >= 4.0.0
* hydra-head >= 6.3.4

## Setup Instructions

For development we follow the typical setup defined in the
[Tutorial: Dive Into Hydra](https://github.com/projecthydra/hydra/wiki/Dive-into-Hydra)
which should include the setup of a Jetty Wrapper to run Fedora and Hydra.

### Additional Configuration

We use the figaro gem for additional application configuration through 'fluctus/config/application.yml' which is added
to the .gitignore file by default.  You will need to copy 'fluctus/config/application.yml.local' to
'fluctus/config/application.yml' and setup values as appropriate.


* Setup APTrust Institution object and Roles

````
# rake task to setup initial insitutions, roles and a default aptrust_admin user.
rake fluctus:setup
````

* Use Proper Solr Configuration

The ```schema.xml``` file in ```solr_conf/conf``` is customized for Fluctus so be sure to use it, or look at the commit history for that file before you deploy Solr in production.

## Heroku Instructions

Note, section dropped as previous fluctus app was deleted.  Intend to rebuild this.

# Querying RDF Datastreams

We are making significant use of RDF Datastreams throughout the application.  Querying
of these is different than traditional rails like model queries and follows a paradim
more similar to earlier rails model queries.

The format is as follows::

  <Class>.where(<rails cased datastream name>__<field name>_tesim: <value>)

So as an example, if you were to query for "APTrust" in the name field of the descMetadata
datastream in the Institution model you would search as follows::

  ins = Institution.where(desc_metadata__name_tesim: "APTrust")
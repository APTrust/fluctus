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

The ```schema.xml``` file in ```solr_conf/conf``` is customized for Fluctus so be sure to use it, or look at the commit
history for that file before you deploy Solr in production.

### Setting up Test Data

* Populating stub data for testing.

There is a simple rake task to setup dummy data in Fedora. by default this rake task sets up 16 or so institutions
(one for each partner), about 5 fake users in each institution, 3-10 Intellectual Objects and 3-30 Generic Files for
each Intellectual Object with a handful of Premis Events for each. Be aware this takes about 20 minutes to run
on most workstations, for a faster setup see the options below the default example.

````
# Without Parameters:
rake fluctus:populate_db

# With Parameters for number_of_institutions, number_of_intellectual_objects, number_of_generic_files:
rake fluctus:populate_db[2,5,5]
````

* Adding additional stub Premis Events to Generic Files

To test longer lists of premis events you can a rake task was added for convenience that will find the first Generic
File object in the repository and add 50 or so fake identifier assignments so we can test the views.
                                                                                                 git
To execute that rake task just type the command:

````
rake fluctus:populate_events
````

Note the Generic File Object pid that will be output so you can use that to load the proper object in the web
interface for testing.

*  Adding an event failure

A simple factory will allow you to add a failed version of any of the current premis events just by
using the factory name and adding _fail at the end.  So to add some fake data for a failed event for
testing you could do the following in code or at command line.

````
# Start by getting the object you want to add the failed event to.
gf = GenericFile.first

# Then add the event as attributes
gf.add_event(FactoryGirl.attributes_for(:premis_events_fixity_check_fail))
gf.save
````

## Heroku Instructions

Note, section dropped as previous fluctus app was deleted.  Intend to rebuild this.

# Notes on Queries

Most quieries are best carried out through the solr index in the formate below.

The format is as follows::

  <Class>.where(<rails cased datastream name>__<field name>_tesim: <value>)

So as an example, if you were to query for "APTrust" in the name field of the descMetadata
datastream in the Institution model you would search as follows::

  ins = Institution.where(desc_metadata__name_tesim: "APTrust")

# Re-indexing objects in solr:

If you re-index an object that has premisEvents, you may also want to re-index the object's events.

```ruby
object = IntellectualObject.first
object.update_index
object.premisEvents.events.each {|e| write_event_to_solr(e) }
```



# Fluctus

## APTrust Admin Console (Hydra Head)

This application aims to use the entire Hydra stack to manage all APTrust interactions with Fedora.  

### Requirements
* Ruby 2.0.0
* Rails 4.0.0
* hydra-head 6.3.0

## Setup Instructions
* Setup APTrust Institution object

````
# Write institution to variable for use later
i = Institution.create!(name: "APTrust")
````

* Setup Fluctus Roles

````
['admin', 'institutional_admin', 'institutional_user'].each do |role|
  Role.create!(name: role)
end
````

      
* Setup First User Account with <strong>your</strong> Google Email.

````
User.create!(name: <your name>, email: <your Google Email>, phone_number: <Your phone number>, institution_name: i.name)
````
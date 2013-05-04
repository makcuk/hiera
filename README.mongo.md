# MongoDb backend


Sometimes you need to update your input data dynamically and in some circumstances dumping information to files 
can be not very convenient. Mongo backend allows you to query different collections from singe database and obtain data after
modifications of third-party systems. Useful in distributed environments with external controllers, which are NoSQL 
oriented. 

# Configuring hiera

Add a new datasource in hiera.yaml

```
:mongo:
  :datadir: mongodb://localhost:27017/hiera
```
Use MongoDB URI to specify database location and credentials (if any). It is possible to leave :datadir: empty, in this case 
default value for URI will be used mongodb://localhost:27017/hiera.
Go to Mongo shell and create database, for example 'hiera'

Now it is possible to use database collections for Hiera lookups. All documents associated with collection will be 
returned into Hiera like with file backends.

```
> use hiera 
> db.createCollection('gateways')
```
Now insert into collection a hash with values. Any type of document is possible, only keep in mind that you need to use it in Puppet, which isn't very flexible in manifests.

```
> gateways = {"smb":{"enabled":true, "running":true}, "nfs":{"enabled":true, "running":true}}
> db.gateways.find()
> { "_id" : ObjectId("517704189846e80638cfc021"), "smb" : { "enabled" : true, "running" : true }, "nfs" : { "enabled" : true, "running" : true } }
```

Running from shell should produce data

```
# hiera gateways
# {"nfs"=>#<BSON::OrderedHash:0x3f852dce9158 {"enabled"=>true, "running"=>true}>, "smb"=>#<BSON::OrderedHash:0x3f852dceaddc {"enabled"=>true, "running"=>true}>}
```

Note, '_id' key is filtered inside Mongo backend and not returned from Hiera. 

# Usage example in Puppet manifest

```
class service_gateways {
                
                $gways = hiera('gateways')  # get data from Hiera
                $services = keys($gways)
                notice(keys($gways))
                define svc::control($params) {
                    service { $name:
                        enable => $params[$name]['enabled'],
                        ensure => $params[$name]['running'],
                    }
                }

                svc::control{$services: params => $gways}  # iterate over keys and feed defined class
}
```
In example above, we just got a list of service and their states, it is easy to extend a list of them from external system.


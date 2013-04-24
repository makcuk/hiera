# MongoDb backend


It is useful to keep input data dynamic, if you have a something which can change them on fly. MongoDB can be used for this purpose. 

# Using

## Configure hiera

Add a new datasource in hiera.yaml

:mongo:
  :datadir: mongodb://localhost:27017/hiera

Use MongoDB URI to specify database location and credentials (if any). Default value for URI is mongodb://localhost:27017/hiera

Create database in Mongo, for example 'hiera'

Now it is possible to use database collections for hiera lookups. All documents associated with collection will be returned into Hiera.

> use hiera
> switched to  
> db.createCollection('gateways')

Now insert into collection a hash with values

> gateways = {"smb":{"enabled":true, "running":true}, "nfs":{"enabled":true, "running":true}}
> db.gateways.find()
> { "_id" : ObjectId("517704189846e80638cfc021"), "smb" : { "enabled" : true, "running" : true }, "nfs" : { "enabled" : true, "running" : true } }

Running from shell should produce data

# hiera gateways
# {"nfs"=>#<BSON::OrderedHash:0x3f852dce9158 {"enabled"=>true, "running"=>true}>, "smb"=>#<BSON::OrderedHash:0x3f852dceaddc {"enabled"=>true, "running"=>true}>}

## Puppet manifest

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

In example above, we just got a list of service and their states, it is easy to extend a list of them from external system.


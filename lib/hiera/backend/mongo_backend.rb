class Hiera
  module Backend
    class Mongo_backend
      def initialize(cache=nil)
        require 'rubygems' # backward compatibility
        require 'mongo'

        mongo_uri = "mongodb://localhost:27017/hiera"
        Hiera.debug("Hiera Mongodb backend starting")
        config_uri = Backend.datadir('mongo', '')
        mongo_uri = config_uri unless not config_uri.include? "mongodb://"
        mongo_client = Mongo::MongoClient.from_uri(uri = mongo_uri)
        @db = mongo_client.db("hiera")
      end

      def lookup(key, scope, order_override, resolution_type)
        answer = nil

        Hiera.debug("Looking up #{key} in Mongodb backend")

        Backend.datasources(scope, order_override) do |source|
          Hiera.debug("Looking for data source #{source}")

          coll = @db.collection(key)
          data = {}
          coll.find({}, {:fields => {'_id' => 0}}).each do |row|
            data.update(row)
          end
          data = nil if data.empty?
          # Mongo do lookups for us and validate them
          # just pass data object as answer
          case resolution_type
            when :array
              raise Exception, "Hiera type mismatch: expected Array and got #{data.class}" unless data.kind_of? Array or data.kind_of? String
              answer ||= []
              answer << data
            when :hash
              raise Exception, "Hiera type mismatch: expected Hash and got #{data.class}" unless data.kind_of? Hash
              answer ||= {}
              answer = Backend.merge_answer(data,answer)
            else
              answer = data
              break
          end
        end

        return answer
      end
    end
  end
end

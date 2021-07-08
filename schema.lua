local typedefs = require "kong.db.schema.typedefs"

return {
    name = "teliksandi",
    fields = {
        { consumer = typedefs.no_consumer },
        { config = {
            type = "record",
            fields = {
              { name = { type = "string", required = true}, },
              { validate_endpoint = { type = "string", required= true}, },
              { redis = { type = "boolean", default = true}, },           
              { redis_host = { type = "string", default = "127.0.0.1"}, },
              { redis_port = { type = "string", default = "6379"}, },   
              { redis_password = { type = "string", default = "secret"}, },
              { redis_expire = { type = "string", default = "60"}, },
            },
          },
        },
    },
    entity_checks = {}
}
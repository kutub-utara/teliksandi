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
            },
          },
        },
    },
    entity_checks = {}
}
local requests = require('requests')
local base64 = require('base64')

local TeliksandiHandler = {
    PRIORITY = 1004,
    VERSION = "1.0.0",
}

-- Run this when the client request hits the service
-- sudo cp handler.lua /usr/local/share/lua/5.1/kong/plugins/teliksandi/handler.lua
-- sudo /usr/local/bin/kong restart -c /etc/kong/kong.conf
-- cat /usr/local/kong/logs/error.log 
function TeliksandiHandler:access(conf)
    local token = kong.request.get_header("x-access-token")

    if token ~= nil and token ~= "" then        
        local headers = {['Authorization'] = 'Bearer ' .. token, ['Accept'] = 'application/json'}

        response = requests.get{conf.validate_endpoint, headers = headers}             

        if response.status_code ~= 200 then
            resp, error = response.json()
            local message = 'Credential was invalid'

            if resp.message ~= nil and resp.message ~= "" then
              message = resp.message
            end

            return kong.response.exit(response.status_code, {success = "false", message = message, code = '01'}, {
                ["Content-Type"] = "application/json"
            })
        end  

        if response.status_code == 200 then
          kong.service.request.set_body({auth_user_kong = response.json()}, "application/json")   
          kong.service.request.add_header("Authorization", 'Bearer ' .. token)     
        end

    else
      if conf.name ~= 'public' then
        return kong.response.exit(403, {success = "false", message = "You must login to reach endpoint", code = '01'}, {
            ["Content-Type"] = "application/json"
        })
      end

    end
                
end

return TeliksandiHandler
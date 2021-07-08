local requests = require('requests')
local base64 = require('base64')
local redis = require('resty.redis')
local json = require('cjson')

local TeliksandiHandler = {
    PRIORITY = 1004,
    VERSION = "1.0.0",
}

-- connect redis
local function connectRedis(conf)
  local cache = redis:new()
  cache:set_timeouts(300, 1000, 1000) -- 1 sec

  local ok, err = cache:connect(conf.redis_host, conf.redis_port)
  if ok then
    local next, err = cache:auth(conf.redis_password)

    if next then
      return cache
    end
  end

  return false
end

-- get data on redis
local function getRedis(conf, token)
    local cache = connectRedis(conf)
    if cache then
      return cache:get(conf.validate_endpoint .. token)
    end    

    return false
end

-- set data on redis
local function setRedis(conf, token, response)
  local cache = connectRedis(conf)
  if cache then
    cache:set(conf.validate_endpoint .. token, response)
    cache:expire(conf.validate_endpoint .. token, conf.redis_expire)
    cache:close()
  end
end

-- hit endpoint to validate
local function getValidate(conf, token)
  local headers = {['Authorization'] = 'Bearer ' .. token, ['Accept'] = 'application/json'}

  local response= requests.get{conf.validate_endpoint, headers = headers}  

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

    if conf.redis then
      setRedis(conf, token, json.encode(response.json()))
    end    
  end
end

-- Run this when the client request hits the service
-- sudo cp handler.lua /usr/local/share/lua/5.1/kong/plugins/teliksandi/handler.lua
-- sudo /usr/local/bin/kong restart -c /etc/kong/kong.conf
-- cat /usr/local/kong/logs/error.log 
function TeliksandiHandler:access(conf)
    local token = kong.request.get_header("x-access-token")

    if token ~= nil and token ~= "" then                                
        if conf.redis then -- redis enable
          local find = getRedis(conf, token)

          if find ~= json.null and find then
            local response = json.decode(find)

            kong.service.request.set_body({auth_user_kong = response}, "application/json")   
            kong.service.request.add_header("Authorization", 'Bearer ' .. token)
          else
            getValidate(conf, token)
          end

        else -- redis disable       
          getValidate(conf, token)
        end

    else -- token not found
      if conf.name ~= 'public' then
        return kong.response.exit(403, {success = "false", message = "You must login to reach endpoint", code = '01'}, {
            ["Content-Type"] = "application/json"
        })
      end

    end
                
end

return TeliksandiHandler
class 'SmartThingsClient'

function SmartThingsClient:new(clientId, clientSecret, refreshToken, refreshCallback)
    self.clientId = clientId
    self.clientSecret = clientSecret
    self.refreshToken = refreshToken
    self.refreshCallback = refreshCallback
    self.baseUrl = "https://api.smartthings.com"
    self.accessToken = ""
    self.http = net.HTTPClient({ timeout = 10000 })
    return self
end

function SmartThingsClient:listDevices(callback)
    local headers = {
        ['Authorization'] = 'Bearer ' .. self.accessToken,
        ["Content-Type"] = "application/json"
    }
    
    self:httpGet("/v1/devices", headers, function(response)
        if response.status == 200 then
            local data = json.decode(response.data)
            callback(data.items)
        else
            QuickApp:error("Failed to list devices. Status: " .. response.status .. " Response: " .. tostring(response.data))
        end
    end)
end

function SmartThingsClient:getDeviceStatus(deviceId, callback)
    local headers = {
        ['Authorization'] = 'Bearer ' .. self.accessToken,
        ["Content-Type"] = "application/json"
    }
    
    self:httpGet("/v1/devices/" .. deviceId .. "/status", headers, function(response)
        if response.status == 200 then
            local data = json.decode(response.data)
            callback(data)
        else
            QuickApp:error("Failed to get device status. Status: " .. response.status .. " Response: " .. tostring(response.data))
        end
    end)
end

function SmartThingsClient:executeCommandsOnDevice(deviceId, commands)
    local headers = {
        ['Authorization'] = 'Bearer ' .. self.accessToken,
        ["Content-Type"] = "application/json"
    }
    local data = json.encode({commands = commands})
    
    self:httpPost("/v1/devices/" .. deviceId .. "/commands", data, headers, function(response)
        if response.status == 200 then
            QuickApp:trace("Commands executed successfully. Status: " .. response.status .. " Data: " .. response.data)
        else
            QuickApp:error("Failed to execute commands. Status: " .. response.status .. " Response: " .. tostring(response.data))
        end
    end)
end

function SmartThingsClient:refreshAccessToken(callback)
    local credentials = base64Encode(self.clientId .. ":" .. self.clientSecret)
    local headers = {
        ['Authorization'] = 'Basic ' .. credentials,
        ['Content-Type'] = 'application/x-www-form-urlencoded',
        ['Accept'] = 'application/json'
    }

    local body = buildFormBody({
        grant_type = 'refresh_token',
        client_id = self.clientId,
        client_secret = self.clientSecret,
        refresh_token = self.refreshToken
    })

    self:httpPost("/oauth/token", body, headers, function(response)
        if response.status == 200 then
            local data = json.decode(response.data)
            if data and data.access_token and data.refresh_token then
                self.accessToken = data.access_token
                self.refreshToken = data.refresh_token
                self.refreshCallback(data.refresh_token)
                
                QuickApp:debug("Token refreshed successfully. Expires in: " .. (data.expires_in or "unknown"))
                
                -- Schedule next refresh 15 minutes before expiry
                local refreshTime = (data.expires_in or 3600) - 900
                if refreshTime > 0 then
                    self:scheduleTokenRefresh(refreshTime)
                else
                    self:scheduleTokenRefresh(60)
                end
                
                if callback then
                    callback()
                end
            else
                QuickApp:error("Token refresh response missing refresh_token and/or access_token")
                self:scheduleTokenRefresh(300)
            end
        else
            QuickApp:error("Failed to refresh token. Status: " .. response.status .. " Response: " .. tostring(response.data))
            self:scheduleTokenRefresh(300)
        end
    end)
end

function SmartThingsClient:scheduleTokenRefresh(refreshInSeconds)
    hub.setTimeout(refreshInSeconds * 1000, function() self:refreshAccessToken() end)
end

function SmartThingsClient:httpGet(endpoint, headers, callback)
    self.http:request(self.baseUrl .. endpoint, {
        options = {
            headers = headers,
            method = "GET"
        },
        success = callback,
        error = function(error)
            QuickApp:error("HTTP GET error: " .. error)
        end
    })
end

function SmartThingsClient:httpPost(endpoint, data, headers, callback)
    self.http:request(self.baseUrl .. endpoint, {
        options = {
            headers = headers,
            method = "POST",
            data = data
        },
        success = callback,
        error = function(error)
            QuickApp:error("HTTP POST error: " .. error)
        end
    })
end

function buildFormBody(params)
    local formParts = {}
    for key, value in pairs(params) do
        if value and value ~= "" then
            table.insert(formParts, urlEncode(key) .. "=" .. urlEncode(value))
        end
    end
    return table.concat(formParts, "&")
end

function urlEncode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w _%%%-%.~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

function base64Encode(data)
    local bC='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    return ((data:gsub('.', function(x) 
            local r,b='',x:byte() for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
            return r;
        end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return bC:sub(c+1,c+1)
        end)..({ '', '==', '=' })[#data%3+1])
end
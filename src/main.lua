QuickApp._trace,TRACE = QuickApp.trace,false
function QuickApp.trace(...) if TRACE then QuickApp._trace(...) end end

function QuickApp:onInit()
    self:debug("SmartThings QuickApp starting...")

    local clientId = self:getVariable("clientId")
    local clientSecret = self:getVariable("clientSecret")
    local refreshToken = self:getVariable("refreshToken")
    
    -- Add debugging to check if variables are loaded
    self:debug("ClientId: " .. (clientId ~="" and clientId or "NOT SET"))
    self:debug("ClientSecret: " .. (clientSecret ~= "" and "SET" or "NOT SET"))
    self:debug("RefreshToken: " .. (refreshToken ~= "" and "SET" or "NOT SET"))
    
    if clientId == "" or clientSecret == "" or refreshToken == "" then
        self:error("Missing required variables. Please check clientId, clientSecret, and refreshToken are set.")
        return
    end
    
    self.client = SmartThingsClient:new(clientId, clientSecret, refreshToken, function(token) self:setVariable("refreshToken", token) end)
    
    -- Load existing children
    self:initChildDevices({
        ["com.fibaro.hvacSystemCool"] = ACDevice
    })

    self.client:refreshAccessToken(function()
        self.client:listDevices(function(data) self:processDiscoveredDevices(data) end)
    end)
end

function QuickApp:processDiscoveredDevices(devices)
    self:debug("Processing " .. #devices .. " discovered devices")

    for _, device in ipairs(devices) do
        -- Check if device is an AC unit (has airConditionerMode capability)
        if self:isACDevice(device) then
            local existingChild = self:findChildByDeviceId(device.deviceId)
            if not existingChild then
                local childId = self:createChildDevice({
                    name = device.label,
                    type = "com.fibaro.hvacSystemCool",
                    initialProperties = {
                        uiView = ACDevice.getUI(),
                        quickAppVariables = {
                            {name = "deviceId", value = device.deviceId},
                            {name = "pollInterval", value = 60}
                        }
                    },
                }, ACDevice)
            else
                self:debug("AC device already exists: " .. device.label)
            end
        else
            self:debug("Device not supported: " .. device.label)
        end
    end
end

function QuickApp:isACDevice(device)
    if not device.components then return false end

    for _, component in ipairs(device.components) do
        if component.capabilities then
            for _, capability in ipairs(component.capabilities) do
                if capability.id == "airConditionerMode" then
                    return true
                end
            end
        end
    end
    return false
end

function QuickApp:findChildByDeviceId(deviceId)
    for _, child in pairs(self.childDevices) do
        if child.deviceId == deviceId then
            return child
        end
    end
    return nil
end

function QuickApp:UIHandler(ev)
  local child = self.childDevices[ev.deviceId] or nil
  if type(child) == nil then
    self:error("Child device not found: " .. ev.deviceId)
    return
  end

  local callback = child.uiCallbacks[ev.elementName][ev.eventType] or ""
  if callback ~= "" then
    child:callAction(callback, ev)
  end
end
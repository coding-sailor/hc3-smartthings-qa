class 'ACDevice' (QuickAppChild)

ACDevice._trace,TRACE = ACDevice.trace,false
function ACDevice.trace(...) if TRACE then ACDevice._trace(...) end end

function ACDevice.getUI()
    return json.decode('[{"components":[{"name":"statusLabel","style":{"weight":"1.0"},"text":"","type":"label","visible":true}],"style":{"weight":"1.0"},"type":"horizontal"},{"components":[{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","auto"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","auto"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","auto"]},"type":"deviceAction"}]},"name":"auto","style":{"weight":"0.20"},"text":"Auto","type":"button","visible":true},{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","low"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","low"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","low"]},"type":"deviceAction"}]},"name":"low","style":{"weight":"0.20"},"text":"Low","type":"button","visible":true},{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","medium"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","medium"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","medium"]},"type":"deviceAction"}]},"name":"medium","style":{"weight":"0.20"},"text":"Med","type":"button","visible":true},{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","high"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","high"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","high"]},"type":"deviceAction"}]},"name":"high","style":{"weight":"0.20"},"text":"High","type":"button","visible":true},{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","turbo"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","turbo"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","turbo"]},"type":"deviceAction"}]},"name":"turbo","style":{"weight":"0.20"},"text":"Turbo","type":"button","visible":true}],"style":{"weight":"1.0"},"type":"horizontal"},{"components":[{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","windFree"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","windFree"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","windFree"]},"type":"deviceAction"}]},"name":"windFree","style":{"weight":"0.50"},"text":"WindFree","type":"button","visible":true},{"eventBinding":{"onLongPressDown":[{"params":{"actionName":"UIAction","args":["onLongPressDown","speed"]},"type":"deviceAction"}],"onLongPressReleased":[{"params":{"actionName":"UIAction","args":["onLongPressReleased","speed"]},"type":"deviceAction"}],"onReleased":[{"params":{"actionName":"UIAction","args":["onReleased","speed"]},"type":"deviceAction"}]},"name":"speed","style":{"weight":"0.50"},"text":"Speed","type":"button","visible":true}],"style":{"weight":"1.0"},"type":"horizontal"}]')
end

function ACDevice:__init(device)
    QuickAppChild.__init(self, device)

    self.deviceId = self:getVariable('deviceId')
    self.pollInterval = self:getVariable('pollInterval')
    self.uiCallbacks = {
        auto = {
            onReleased = "setFanMode"
        },
        low = {
            onReleased = "setFanMode"
        },
        medium = {
            onReleased = "setFanMode"
        },
        high = {
            onReleased = "setFanMode"
        },
        turbo = {
            onReleased = "setFanMode"
        },
        windFree = {
            onReleased = "setOptionalMode"
        },
        speed = {
            onReleased = "setOptionalMode"
        }
    }

    self:updateProperty("supportedThermostatModes", {"Off", "Cool"})
    self:updateProperty("coolingThermostatSetpointCapabilitiesMin", 16)
    self:updateProperty("coolingThermostatSetpointCapabilitiesMax", 30)
    self:updateProperty("coolingThermostatSetpointStep", { C = 1, F = 1})
    self:updateProperty("coolingThermostatSetpoint", { value= 22, unit= "C" })

    self:debug("AC device initialized: " .. self.name)

    hub.setTimeout(math.random(10000, 15000), function() self:pollStatus() end)
end

function ACDevice:pollStatus()
    self.parent.client:getDeviceStatus(self.deviceId, function(data) self:updateStatus(data) end)
    hub.setTimeout(self.pollInterval * 1000, function() self:pollStatus() end) -- Set the next poll
end

function ACDevice:updateStatus(data)
    local main = data.components.main
    local switchState = main.switch.switch.value
    local temperature = main.thermostatCoolingSetpoint.coolingSetpoint.value
    local fanMode = main.airConditionerFanMode.fanMode.value
    local mode = main.airConditionerMode.airConditionerMode.value
    local optionalMode = main["custom.airConditionerOptionalMode"].acOptionalMode.value

    if switchState == 'on' and mode == 'cool' then
        self:updateProperty("thermostatMode", "Cool")
        self:displayCustomControls(true)
    elseif switchState == 'off' then
        self:updateProperty("thermostatMode", "Off")
        self:displayCustomControls(false)
    else
        self:updateProperty("thermostatMode", "Other")
        self:displayCustomControls(false)
    end

    self:updateProperty("acFanMode", fanMode)
    self:updateProperty("acOptionalMode", optionalMode)
    self:updateProperty("coolingThermostatSetpoint", { value= temperature, unit= "C" })

    self:updateStatusLabel(fanMode, optionalMode)

    self:trace(self.name .. " AC is " .. switchState .. ", Temp: " .. temperature .. "°C, Fan: " .. fanMode .. ", Mode: " .. mode .. ", Optional mode: " .. optionalMode)
end

function ACDevice:setThermostatMode(mode)
    if mode == "Off" then
        self:updateProperty("thermostatMode", mode)
        self.parent.client:executeCommandsOnDevice(self.deviceId, {
            {
                component = "main",
                capability = "switch",
                command = "off"
            }
        })
        self:displayCustomControls(false)
    elseif mode == "Cool" then
        self:updateProperty("thermostatMode", mode)
        self:updateProperty("acFanMode", "auto")
        self.parent.client:executeCommandsOnDevice(self.deviceId, {
            {
                component = "main",
                capability = "switch",
                command = "on"
            },
            {
                component = "main",
                capability = "airConditionerMode",
                command = "setAirConditionerMode",
                arguments = {"cool"}
            },
            {
                component = "main",
                capability = "airConditionerFanMode",
                command = "setFanMode",
                arguments = {"auto"}
            }
        })
        self:displayCustomControls(true)
        self:updateStatusLabel("auto", nil)
    end
end

function ACDevice:setCoolingThermostatSetpoint(value) 
    self.parent.client:executeCommandsOnDevice(self.deviceId, {
            {
                component = "main",
                capability = "thermostatCoolingSetpoint",
                command = "setCoolingSetpoint",
                arguments = {value}
            }
        })
    self:updateProperty("coolingThermostatSetpoint", { value= value, unit= "C" })
end

function ACDevice:setFanMode(event)
    local fanMode = event.elementName

    self:updateProperty("acFanMode", fanMode)
    self.parent.client:executeCommandsOnDevice(self.deviceId, {
        {
            component = "main",
            capability = "airConditionerFanMode",
            command = "setFanMode",
            arguments = {fanMode}
        }
    })
    self:updateStatusLabel(fanMode, nil)
end

function ACDevice:setOptionalMode(event)
    local mode = event.elementName

    if self.properties.acOptionalMode == mode then
        self:updateProperty("acFanMode", "auto")
        self:updateProperty("acOptionalMode", "off")
        self.parent.client:executeCommandsOnDevice(self.deviceId, {
            {
                component = "main",
                capability = "airConditionerFanMode",
                command = "setFanMode",
                arguments = {"auto"}
            },
            {
                component = "main",
                capability = "custom.airConditionerOptionalMode",
                command = "setAcOptionalMode",
                arguments = {"off"}
            }
        })
        self:displayFanButtons(true)
        self:updateStatusLabel("auto", "off")
    else
        self:updateProperty("acOptionalMode", mode)
        self.parent.client:executeCommandsOnDevice(self.deviceId, {
            {
                component = "main",
                capability = "custom.airConditionerOptionalMode",
                command = "setAcOptionalMode",
                arguments = {mode}
            }
        })
        self:displayFanButtons(false)
        self:updateStatusLabel(nil, mode)
    end
end

function ACDevice:updateStatusLabel(fanMode, optionalMode)
    fanMode = fanMode or self.properties.acFanMode
    optionalMode = optionalMode or self.properties.acOptionalMode

    if(optionalMode ~= "off") then
        self:updateView("statusLabel", "text", "Mode: " .. tostring(optionalMode))
    else
        self:updateView("statusLabel", "text", "Fan: " .. tostring(fanMode))
    end
end

function ACDevice:displayFanButtons(visible)
    self:updateView("auto", "visible", visible)
    self:updateView("low", "visible", visible)
    self:updateView("medium", "visible", visible)
    self:updateView("high", "visible", visible)
    self:updateView("turbo", "visible", visible)
end

function ACDevice:displayCustomControls(visible)
    self:displayFanButtons(visible)
    self:updateView("windFree", "visible", visible)
    self:updateView("speed", "visible", visible)
    self:updateView("statusLabel", "visible", visible)
end

--[[
    =============================================================================
    ROBLOX LUAU SCRIPT INTERCEPTOR & SOURCE AUDITOR (ANTI-TAMPER READY)
    =============================================================================
    Description:
        Hooks `game:HttpGet`, `game:HttpGetAsync`, and global `loadstring`
        to intercept, audit, and save fetched script payloads locally.
        Includes metatable protection handling (`setreadonly`, `getrawmetatable`,
        `checkcaller`, `newcclosure`) to handle anti-tamper checks.
    =============================================================================
--]]

local Interceptor = {
    OutputFileName = "script.lua",
    AutoSave = true,
    Verbose = true
}

-- Utility logger
local function log(msg)
    if Interceptor.Verbose then
        print("[ScriptInterceptor] " .. tostring(msg))
    end
end

-- File writer wrapper
local function saveInterceptedSource(sourceCode, sourceOrigin)
    sourceOrigin = sourceOrigin or "Unknown Source"
    log("Intercepted payload (" .. #sourceCode .. " bytes) from: " .. sourceOrigin)

    if writefile then
        local success, err = pcall(function()
            writefile(Interceptor.OutputFileName, sourceCode)
        end)
        if success then
            log("Successfully saved intercepted script to workspace: " .. Interceptor.OutputFileName)
        else
            warn("[ScriptInterceptor] Failed to write file: " .. tostring(err))
        end
    else
        log("`writefile` function unavailable. Outputting script payload:")
        print("====================== BEGIN CAPTURED CODE ======================")
        print(sourceCode)
        print("======================= END CAPTURED CODE =======================")
    end
end

-- Anti-tamper safe metatable modifier helper
local function safeHookNamecall()
    local rawMetatable = (getrawmetatable and getrawmetatable(game)) or getmetatable(game)
    if not rawMetatable then
        warn("[ScriptInterceptor] Unable to access DataModel metatable.")
        return false
    end

    -- Handle read-only metatable status (anti-tamper protection)
    local isReadOnly = false
    if isreadonly then
        isReadOnly = isreadonly(rawMetatable)
    end

    if setreadonly then
        setreadonly(rawMetatable, false)
    elseif make_writeable then
        make_writeable(rawMetatable)
    end

    local oldNamecall = rawMetatable.__namecall

    rawMetatable.__namecall = newcclosure(function(self, ...)
        local method = (getnamecallmethod and getnamecallmethod())
        
        -- Filter for network GET calls targeting game object
        if self == game and (method == "HttpGet" or method == "HttpGetAsync") then
            local args = {...}
            local url = args[1]
            log("Intercepted network fetch: game:" .. tostring(method) .. "(" .. tostring(url) .. ")")

            -- Pass execution to original namecall
            local responsePayload = oldNamecall(self, ...)
            
            if type(responsePayload) == "string" and Interceptor.AutoSave then
                saveInterceptedSource(responsePayload, url)
            end
            return responsePayload
        end

        return oldNamecall(self, ...)
    end)

    -- Restore original read-only state to prevent anti-tamper flag
    if setreadonly then
        setreadonly(rawMetatable, isReadOnly)
    elseif make_readonly then
        make_readonly(rawMetatable)
    end

    log("Installed safe metamethod hook on game.__namecall")
    return true
end

-- 1. Install namecall metamethod hook
if hookmetamethod and getnamecallmethod then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if self == game and (method == "HttpGet" or method == "HttpGetAsync") then
            local args = {...}
            local url = args[1]
            log("Intercepted network request: game:" .. tostring(method) .. "(" .. tostring(url) .. ")")

            local responsePayload = oldNamecall(self, ...)
            if type(responsePayload) == "string" and Interceptor.AutoSave then
                saveInterceptedSource(responsePayload, url)
            end
            return responsePayload
        end
        return oldNamecall(self, ...)
    end))
    log("Installed hook via hookmetamethod")
else
    -- Fallback to manual metatable unprotecting & hooking
    safeHookNamecall()
end

-- 2. Hook global loadstring function
if hookfunction and loadstring then
    local oldLoadstring
    oldLoadstring = hookfunction(loadstring, newcclosure(function(codeString, chunkName)
        log("Intercepted loadstring execution (Chunk: " .. tostring(chunkName or "Unnamed") .. ")")
        if type(codeString) == "string" and Interceptor.AutoSave then
            saveInterceptedSource(codeString, "loadstring payload: " .. tostring(chunkName or "unnamed"))
        end
        return oldLoadstring(codeString, chunkName)
    end))
    log("Successfully installed hook on global loadstring")
else
    warn("[ScriptInterceptor] `hookfunction` unavailable.")
end

-- 3. Execution wrapper to run target script string under active hooks
function Interceptor.Execute(targetLoadstring)
    log("Executing target loadstring under active interceptor...")
    local compiledFunc, err
    if type(targetLoadstring) == "string" then
        compiledFunc, err = loadstring(targetLoadstring)
        if not compiledFunc then
            warn("[ScriptInterceptor] Syntax error in provided target: " .. tostring(err))
            return false
        end
    elseif type(targetLoadstring) == "function" then
        compiledFunc = targetLoadstring
    else
        warn("[ScriptInterceptor] Invalid target type provided.")
        return false
    end

    local execSuccess, execErr = pcall(compiledFunc)
    if not execSuccess then
        warn("[ScriptInterceptor] Runtime execution error: " .. tostring(execErr))
    end
    return execSuccess
end

return Interceptor

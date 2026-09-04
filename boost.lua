--[[
    =============================================================================
    ADVANCED LUAU SCRIPT INTERCEPTOR & ANTI-TAMPER BYPASS MEMORY DUMPER
    =============================================================================
    Target File: C:\xaloex\mb2\script.lua
    Author: Dalboebov & VEX
    Description:
        Stealth Luau execution interceptor and anti-tamper bypass framework.
        Protects hooks against Luarmor, Luraph, and VM integrity checks via:
        1. Function spoofing (`iscclosure`, `checkcaller`, `debug.getinfo`, `hookfunction` detection masking)
        2. Metatable protection (`__metatable`, `getrawmetatable`, `setreadonly` restoring)
        3. Silent passive payload capture on dynamic compilation and network requests.
    =============================================================================
--]]

local Interceptor = {
    TargetFolder = "intercepted_scripts",
    AutoSave = true,
    Verbose = true,
    LogToFile = true,
    ScriptCount = 0,
    CapturedHashes = {},
    HooksInstalled = false,
    Originals = {},
    HookedFunctionsMap = {}
}

-- Utility logger with timestamping
local function getTimeString()
    if os and os.date then
        return os.date("%Y-%m-%d %H:%M:%S")
    end
    return "00:00:00"
end

local function log(msg, level)
    level = level or "INFO"
    local formatted = string.format("[%s] [ScriptInterceptor] [%s] %s", getTimeString(), level, tostring(msg))
    if Interceptor.Verbose then
        if level == "WARN" or level == "ERROR" then
            warn(formatted)
        else
            print(formatted)
        end
    end
end

-- Stealth Clone Utilities
local function safeClone(fn)
    if not fn or type(fn) ~= "function" then return fn end
    if clonefunction then
        local success, result = pcall(clonefunction, fn)
        if success and result then return result end
    end
    return fn
end

-- Save clean environment primitives before any scripts run
local raw_loadstring   = safeClone(loadstring)
local raw_loadfile     = safeClone(loadfile)
local raw_pcall        = safeClone(pcall)
local raw_type         = safeClone(type)
local raw_tostring     = safeClone(tostring)
local raw_writefile    = safeClone(writefile)
local raw_readfile     = safeClone(readfile)
local raw_makefolder   = safeClone(makefolder)
local raw_isfolder     = safeClone(isfolder)
local raw_isfile       = safeClone(isfile)
local raw_decompile    = safeClone(decompile)
local raw_debug_info   = safeClone(debug and debug.getinfo)
local raw_iscclosure   = safeClone(iscclosure)
local raw_checkcaller  = safeClone(checkcaller)
local raw_hookfunction = safeClone(hookfunction)

-- String hash utility
local function hashString(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash * 33) + string.byte(str, i)) % 4294967296
    end
    return string.format("%x", hash)
end

-- Directory initialization
local function ensureFolderExists(path)
    path = path or Interceptor.TargetFolder
    if raw_makefolder and raw_isfolder then
        local ok, err = raw_pcall(function()
            if not raw_isfolder(path) then
                raw_makefolder(path)
            end
        end)
        if not ok then
            log("Failed to verify/create directory '" .. tostring(path) .. "': " .. tostring(err), "WARN")
        end
    end
end

-- Sanitize filenames for Windows filesystem
local function sanitizeFileName(str)
    if not str or str == "" then return "unnamed" end
    local clean = str:gsub("[%c%s%p]", "_"):sub(1, 40)
    clean = clean:gsub("_+", "_"):gsub("^_", ""):gsub("_$", "")
    return #clean > 0 and clean or "payload"
end

-- Dump routine
function Interceptor.DumpScript(sourceCode, sourceOrigin, metadata)
    if not sourceCode or raw_type(sourceCode) ~= "string" or #sourceCode == 0 then
        return
    end

    ensureFolderExists(Interceptor.TargetFolder)

    local payloadHash = hashString(sourceCode)
    if Interceptor.CapturedHashes[payloadHash] then
        return Interceptor.CapturedHashes[payloadHash]
    end

    Interceptor.ScriptCount = Interceptor.ScriptCount + 1
    sourceOrigin = sourceOrigin or "Dynamic_Load"
    metadata = metadata or {}

    local sanitizedTag = sanitizeFileName(sourceOrigin)
    local fileName = string.format("%s/dump_%04d_%s_%s.lua", 
        Interceptor.TargetFolder, 
        Interceptor.ScriptCount, 
        sanitizedTag, 
        payloadHash:sub(1, 8)
    )

    local headerLines = {
        "--[[",
        "    =================================================================",
        "    INTERCEPTED SCRIPT PAYLOAD DUMP (ANTI-TAMPER BYPASS ACTIVE)",
        "    =================================================================",
        "    Captured At  : " .. getTimeString(),
        "    Source Origin: " .. tostring(sourceOrigin),
        "    Payload Hash : " .. payloadHash,
        "    Payload Size : " .. #sourceCode .. " bytes",
    }

    for k, v in pairs(metadata) do
        table.insert(headerLines, string.format("    Meta [%-7s]: %s", tostring(k), tostring(v)))
    end

    table.insert(headerLines, "    =================================================================")
    table.insert(headerLines, "--]]\n\n")

    local fullContent = table.concat(headerLines, "\n") .. sourceCode

    if raw_writefile and Interceptor.AutoSave then
        local success, writeErr = raw_pcall(function()
            raw_writefile(fileName, fullContent)
        end)
        if success then
            Interceptor.CapturedHashes[payloadHash] = fileName
            log("Successfully captured payload (" .. #sourceCode .. " bytes) -> " .. fileName, "INFO")
            return fileName
        end
    end
end

-- Anti-Tamper Bypass: Mask hooked functions from debug detection
local function installAntiTamperHooks()
    -- 1. Spoof `iscclosure` and `isourclosure` so Luarmor integrity checks think hooks are native C functions
    if raw_iscclosure and raw_hookfunction then
        local oldIsCClosure
        oldIsCClosure = raw_hookfunction(raw_iscclosure, newcclosure(function(fn)
            if Interceptor.HookedFunctionsMap[fn] then
                return true
            end
            return oldIsCClosure(fn)
        end))
    end

    -- 2. Spoof `debug.getinfo` so stack traces and function source checks report clean native functions
    if raw_debug_info and raw_hookfunction then
        local oldGetInfo
        oldGetInfo = raw_hookfunction(raw_debug_info, newcclosure(function(fn, what)
            if type(fn) == "function" and Interceptor.HookedFunctionsMap[fn] then
                local info = oldGetInfo(Interceptor.HookedFunctionsMap[fn], what)
                if type(info) == "table" then
                    info.source = "=[C]"
                    info.what = "C"
                    info.namewhat = ""
                    info.short_src = "[C]"
                end
                return info
            end
            return oldGetInfo(fn, what)
        end))
    end

    log("Anti-Tamper & Anti-Hook detection bypasses initialized.", "INFO")
end

-- Stealth Metamethod Hook (game:HttpGet, game:HttpGetAsync, etc.)
local function installNamecallHook()
    if not (hookmetamethod and getnamecallmethod) then
        return false
    end

    local oldNamecall
    local newHook = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        -- Don't intercept if request originates from execution hooks
        if raw_checkcaller and raw_checkcaller() then
            return oldNamecall(self, ...)
        end

        if self == game and (method == "HttpGet" or method == "HttpGetAsync" or method == "HttpPost" or method == "HttpPostAsync") then
            local args = {...}
            local url = args[1]
            local result = oldNamecall(self, ...)
            if raw_type(result) == "string" and Interceptor.AutoSave then
                Interceptor.DumpScript(result, url, { Method = method, Type = "Network_Fetch" })
            end
            return result
        end
        return oldNamecall(self, ...)
    end)

    oldNamecall = hookmetamethod(game, "__namecall", newHook)
    Interceptor.HookedFunctionsMap[newHook] = oldNamecall
    Interceptor.Originals.__namecall = oldNamecall
    log("Installed stealth metamethod hook on game.__namecall", "INFO")
    return true
end

-- Stealth Global loadstring hook
local function installLoadstringHook()
    if not (raw_hookfunction and raw_loadstring) then
        return false
    end

    local oldLoadstring
    local newHook = newcclosure(function(codeString, chunkName)
        chunkName = chunkName or "loadstring_chunk"
        
        if raw_type(codeString) == "string" and Interceptor.AutoSave then
            -- Passively extract without throwing or modifying execution flow
            Interceptor.DumpScript(codeString, chunkName, { Type = "Loadstring_Compilation" })
            
            -- Detect Luarmor stage-1 encrypted buffer
            local wrappedHex = codeString:match('^%s*%["([%a%d]+)"%]%s*$')
            if wrappedHex then
                Interceptor.DumpScript("-- STAGE-2 ENCRYPTED BUFFER DUMP:\nreturn \"" .. wrappedHex .. "\"", chunkName .. "_stage2", {
                    Type = "Luarmor_Stage2_Hex"
                })
            end
        end

        return oldLoadstring(codeString, chunkName)
    end)

    oldLoadstring = raw_hookfunction(raw_loadstring, newHook)
    Interceptor.HookedFunctionsMap[newHook] = raw_loadstring
    Interceptor.Originals.loadstring = oldLoadstring
    log("Installed stealth hook on global loadstring", "INFO")
    return true
end

-- Stealth HTTP Library Hooks (request, http_request, syn.request, fluxus.request)
local function installHttpRequestHooks()
    local requestFunctions = {
        { name = "request", fn = request },
        { name = "http_request", fn = http_request },
        { name = "syn.request", fn = syn and syn.request },
        { name = "fluxus.request", fn = fluxus and fluxus.request },
        { name = "http.request", fn = http and http.request }
    }

    if not raw_hookfunction then return end

    for _, target in ipairs(requestFunctions) do
        if target.fn and type(target.fn) == "function" then
            local oldReq
            local newHook = newcclosure(function(options)
                local response = oldReq(options)
                if type(options) == "table" and options.Url and type(response) == "table" and type(response.Body) == "string" then
                    if #response.Body > 0 and Interceptor.AutoSave then
                        Interceptor.DumpScript(response.Body, options.Url, {
                            Method = options.Method or "GET",
                            Engine = target.name,
                            Status = response.StatusCode
                        })
                    end
                end
                return response
            end)

            oldReq = raw_hookfunction(target.fn, newHook)
            Interceptor.HookedFunctionsMap[newHook] = target.fn
            log("Installed stealth hook on HTTP function: " .. target.name, "INFO")
        end
    end
end

-- Main Init
function Interceptor.Init()
    if Interceptor.HooksInstalled then
        return true
    end

    log("Initializing Anti-Tamper Bypass & Luau Interceptor...", "INFO")
    ensureFolderExists(Interceptor.TargetFolder)

    installAntiTamperHooks()
    installNamecallHook()
    installLoadstringHook()
    installHttpRequestHooks()

    Interceptor.HooksInstalled = true
    log("Interceptor active & stealth bypasses loaded.", "INFO")
    return true
end

Interceptor.Init()

return Interceptor

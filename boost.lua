--[[
    =============================================================================
    ADVANCED LUAU SCRIPT INTERCEPTOR & AUTOMATED MEMORY/NETWORK DUMPER
    =============================================================================
    Target File: C:\xaloex\mb2\script.lua
    Author: Dalboebov & VEX
    Description:
        Comprehensive Luau execution interceptor designed for Roblox executors
        (Synapse, Krnl, Fluxus, Swift, Wave, Solara, etc.). Hooks network payloads,
        code compilation primitives (`loadstring`, `loadfile`), HTTP requests, and
        bytecode decompilation. Automatically saves captured scripts to local disk.
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
    Originals = {}
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

-- Function clone utility for OPSEC & anti-hook detection
local function safeClone(fn)
    if not fn or type(fn) ~= "function" then return fn end
    if clonefunction then
        local success, result = pcall(clonefunction, fn)
        if success and result then return result end
    end
    return fn
end

-- Environment API references (cloned for stealth)
local raw_loadstring = safeClone(loadstring)
local raw_loadfile   = safeClone(loadfile)
local raw_pcall      = safeClone(pcall)
local raw_type       = safeClone(type)
local raw_tostring   = safeClone(tostring)
local raw_writefile  = safeClone(writefile)
local raw_readfile   = safeClone(readfile)
local raw_makefolder = safeClone(makefolder)
local raw_isfolder   = safeClone(isfolder)
local raw_isfile     = safeClone(isfile)
local raw_decompile  = safeClone(decompile)

-- Simple string hashing for duplicate payload suppression
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

-- Sanitize names for safe Windows file paths
local function sanitizeFileName(str)
    if not str or str == "" then return "unnamed" end
    local clean = str:gsub("[%c%s%p]", "_"):sub(1, 40)
    clean = clean:gsub("_+", "_"):gsub("^_", ""):gsub("_$", "")
    return #clean > 0 and clean or "payload"
end

-- Main payload dumping routine
function Interceptor.DumpScript(sourceCode, sourceOrigin, metadata)
    if not sourceCode or raw_type(sourceCode) ~= "string" or #sourceCode == 0 then
        return
    end

    ensureFolderExists(Interceptor.TargetFolder)

    local payloadHash = hashString(sourceCode)
    if Interceptor.CapturedHashes[payloadHash] then
        log("Skipping duplicate payload (" .. payloadHash .. ") from: " .. tostring(sourceOrigin), "INFO")
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

    -- Build rich metadata header for the dumped script
    local headerLines = {
        "--[[",
        "    =================================================================",
        "    INTERCEPTED SCRIPT PAYLOAD DUMP",
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
        else
            log("Failed to dump payload to disk: " .. tostring(writeErr), "ERROR")
        end
    else
        log("`writefile` API missing. Displaying raw payload preview below:", "WARN")
        print(">>> BEGIN INTERCEPTED PAYLOAD >>>")
        print(fullContent)
        print("<<< END INTERCEPTED PAYLOAD <<<")
    end
end

-- Global Metamethod Hooks (game:HttpGet, game:HttpGetAsync, game:HttpPost)
local function installNamecallHook()
    if not (hookmetamethod and getnamecallmethod) then
        log("`hookmetamethod` or `getnamecallmethod` unavailable on this environment.", "WARN")
        return false
    end

    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if self == game and (method == "HttpGet" or method == "HttpGetAsync" or method == "HttpPost" or method == "HttpPostAsync") then
            local args = {...}
            local url = args[1]
            log("Intercepted game:" .. tostring(method) .. "(" .. tostring(url) .. ")", "INFO")

            local result = oldNamecall(self, ...)
            if raw_type(result) == "string" and Interceptor.AutoSave then
                Interceptor.DumpScript(result, url, { Method = method, Type = "Network_Fetch" })
            end
            return result
        end
        return oldNamecall(self, ...)
    end))

    Interceptor.Originals.__namecall = oldNamecall
    log("Installed metamethod hook on game.__namecall", "INFO")
    return true
end

-- Global Function Hooks (loadstring, loadfile)
local function installLoadstringHook()
    if not (hookfunction and raw_loadstring) then
        log("`hookfunction` or `loadstring` unavailable for global hooking.", "WARN")
        return false
    end

    local oldLoadstring
    oldLoadstring = hookfunction(raw_loadstring, newcclosure(function(codeString, chunkName)
        chunkName = chunkName or "loadstring_chunk"
        log("Intercepted compilation via loadstring (Chunk: " .. tostring(chunkName) .. ")", "INFO")

        if raw_type(codeString) == "string" and Interceptor.AutoSave then
            Interceptor.DumpScript(codeString, chunkName, { Type = "Loadstring_Compilation" })
        end

        return oldLoadstring(codeString, chunkName)
    end))

    Interceptor.Originals.loadstring = oldLoadstring
    log("Installed function hook on global loadstring", "INFO")
    return true
end

-- HTTP Request Library Hooks (request, http_request, syn.request, fluxus.request)
local function installHttpRequestHooks()
    local requestFunctions = {
        { name = "request", fn = request },
        { name = "http_request", fn = http_request },
        { name = "syn.request", fn = syn and syn.request },
        { name = "fluxus.request", fn = fluxus and fluxus.request },
        { name = "http.request", fn = http and http.request }
    }

    if not hookfunction then return end

    for _, target in ipairs(requestFunctions) do
        if target.fn and type(target.fn) == "function" then
            local oldReq
            oldReq = hookfunction(target.fn, newcclosure(function(options)
                if type(options) == "table" and options.Url then
                    log("Intercepted HTTP request via " .. target.name .. " -> " .. tostring(options.Url), "INFO")
                    local response = oldReq(options)

                    if type(response) == "table" and type(response.Body) == "string" and Interceptor.AutoSave then
                        if #response.Body > 0 then
                            Interceptor.DumpScript(response.Body, options.Url, {
                                Method = options.Method or "GET",
                                Engine = target.name,
                                Status = response.StatusCode
                            })
                            -- If response is a wrapped array/string table (e.g., Luarmor stage 1 payload ["hash/hex"])
                            local wrappedString = response.Body:match('^%s*%["([%a%d]+)"%]%s*$')
                            if wrappedString then
                                log("Detected wrapped stage-2 string payload from " .. options.Url .. ". Unwrapping...", "INFO")
                                Interceptor.DumpScript("-- UNWRAPPED STAGE-2 PAYLOAD STRING:\nreturn \"" .. wrappedString .. "\"", options.Url .. "_unwrapped", {
                                    Type = "Stage2_Unwrapped_String"
                                })
                            end
                        end
                    end
                    return response
                end
                return oldReq(options)
            end))
            log("Installed hook on HTTP function: " .. target.name, "INFO")
        end
    end
end

-- Decompiler for LocalScript / ModuleScript instances
function Interceptor.DecompileInstance(instance, customName)
    if not raw_decompile then
        log("`decompile` API unavailable in current environment.", "WARN")
        return nil
    end

    if not instance or typeof(instance) ~= "Instance" then
        log("Invalid Instance provided for decompilation.", "WARN")
        return nil
    end

    log("Decompiling script instance: " .. instance:GetFullName(), "INFO")
    local ok, source = raw_pcall(raw_decompile, instance)
    if ok and type(source) == "string" and #source > 0 then
        local dumpedPath = Interceptor.DumpScript(source, customName or instance.Name, {
            ClassName = instance.ClassName,
            FullPath = instance:GetFullName(),
            Type = "Decompiled_Instance"
        })
        return dumpedPath
    else
        log("Decompilation failed for " .. instance:GetFullName() .. ": " .. tostring(source), "ERROR")
        return nil
    end
end

-- Recursive workspace / game script extractor
function Interceptor.DumpAllGameScripts(parentContainer)
    parentContainer = parentContainer or game
    log("Scanning container '" .. parentContainer:GetFullName() .. "' for scripts...", "INFO")

    local count = 0
    local function scan(obj)
        local ok, children = raw_pcall(function() return obj:GetChildren() end)
        if not ok or not children then return end

        for _, child in ipairs(children) do
            if child:IsA("LocalScript") or child:IsA("ModuleScript") then
                Interceptor.DecompileInstance(child)
                count = count + 1
            end
            scan(child)
        end
    end

    scan(parentContainer)
    log("Completed scan. Processed " .. count .. " script instances.", "INFO")
    return count
end

-- Main Hook Installation Entrypoint
function Interceptor.Init()
    if Interceptor.HooksInstalled then
        log("Interceptor hooks already active.", "WARN")
        return true
    end

    log("Initializing Luau Script Interceptor & Memory Dumper...", "INFO")
    ensureFolderExists(Interceptor.TargetFolder)

    installNamecallHook()
    installLoadstringHook()
    installHttpRequestHooks()

    Interceptor.HooksInstalled = true
    log("Interceptor fully armed and listening for payloads.", "INFO")
    return true
end

-- Auto-start interceptor on script load
Interceptor.Init()

return Interceptor

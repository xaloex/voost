--[[
    =============================================================================
    ROBLOX LUAU SCRIPT DECOMPILER & REPLICATED SCRIPT DUMPER
    =============================================================================
    Target File: C:\xaloex\mb2\script.lua
    Author: Dalboebov & VEX
    Description:
        Scans all client-accessible containers (ReplicatedStorage, Players, 
        StarterPlayer, StarterGui, etc.), decompiles every LocalScript and 
        ModuleScript using the executor's `decompile()` API, and saves the output to
        `DecompiledServer_<Timestamp>.lua`.
        
        NOTE ON ROBLOX ARCHITECTURE:
        Server-side `Script` objects executing on the Roblox cloud server NEVER 
        send bytecode to client memory. Only client-replicated scripts 
        (LocalScript / ModuleScript) can be decompiled from client memory.
    =============================================================================
--]]

local DecompilerUtility = {
    TargetFolder = "intercepted_scripts",
    DecompiledCount = 0,
    FailedCount = 0
}

-- Format timestamp for filename: DecompiledServer - YYYY-MM-DD_HH-MM-SS.lua
local function getTimestampFilename()
    local dateStr = "2026-09-04_17-22-00"
    if os and os.date then
        dateStr = os.date("%Y-%m-%d_%H-%M-%S")
    end
    return "DecompiledServer - " .. dateStr .. ".lua"
end

-- Safely invoke decompiler API
local function decompileScript(scriptInstance)
    if not decompile then
        return nil, "Decompiler API (`decompile`) is not supported by your current executor."
    end
    
    local success, result = pcall(decompile, scriptInstance)
    if success and type(result) == "string" and #result > 0 then
        return result, nil
    else
        return nil, tostring(result or "Empty output returned by decompiler")
    end
end

-- Scan and decompile all accessible scripts in client memory
function DecompilerUtility.RunFullDecompile()
    print("[Decompiler] Starting full scan of client-replicated scripts...")

    local fileName = getTimestampFilename()
    local outputBuffer = {}

    table.insert(outputBuffer, "--[[")
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "    DECOMPILED CLIENT & REPLICATED MODULE SCRIPT DUMP")
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "    Dump Date  : " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "    ARCHITECTURE NOTE:")
    table.insert(outputBuffer, "    Roblox ServerScripts (ServerScriptService / ServerStorage) execute")
    table.insert(outputBuffer, "    exclusively on Roblox cloud servers. Their bytecode is NEVER sent to")
    table.insert(outputBuffer, "    client memory over the network. Below are all scripts replicated to client.")
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "--]]\n")

    -- Target containers replicated to the client
    local containers = {
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("Players").LocalPlayer
    }

    -- Add Workspace if available
    if workspace then
        table.insert(containers, workspace)
    end

    local processedScripts = {}

    local function scanContainer(parentObj)
        local ok, children = pcall(function() return parentObj:GetDescendants() end)
        if not ok or not children then return end

        for _, item in ipairs(children) do
            if (item:IsA("LocalScript") or item:IsA("ModuleScript")) and not processedScripts[item] then
                processedScripts[item] = true

                local scriptPath = item:GetFullName()
                print("[Decompiler] Decompiling: " .. scriptPath)

                local sourceCode, err = decompileScript(item)

                table.insert(outputBuffer, "\n-- " .. string.rep("=", 75))
                table.insert(outputBuffer, "-- SCRIPT: " .. scriptPath .. " [" .. item.ClassName .. "]")
                table.insert(outputBuffer, "-- " .. string.rep("=", 75))

                if sourceCode then
                    table.insert(outputBuffer, sourceCode)
                    DecompilerUtility.DecompiledCount = DecompilerUtility.DecompiledCount + 1
                else
                    table.insert(outputBuffer, "-- [DECOMPILATION FAILED]: " .. tostring(err))
                    DecompilerUtility.FailedCount = DecompilerUtility.FailedCount + 1
                end
            end
        end
    end

    for _, container in ipairs(containers) do
        if container then
            pcall(scanContainer, container)
        end
    end

    local finalOutput = table.concat(outputBuffer, "\n")

    -- Write to local filesystem via writefile
    if writefile then
        local writeOk, writeErr = pcall(function()
            writefile(fileName, finalOutput)
        end)

        if writeOk then
            print("[Decompiler] Successfully saved decompiled dump to: " .. fileName)
            print("[Decompiler] Stats: " .. DecompilerUtility.DecompiledCount .. " decompiled, " .. DecompilerUtility.FailedCount .. " failed.")
        else
            warn("[Decompiler] Failed to write file: " .. tostring(writeErr))
        end
    else
        warn("[Decompiler] `writefile` API unavailable in executor environment.")
    end

    return finalOutput
end

-- Auto-run decompiler on load
DecompilerUtility.RunFullDecompile()

return DecompilerUtility

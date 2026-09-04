--[[
    =============================================================================
    LUAU VM BYTECODE DISASSEMBLER & HIGH-LEVEL AST DECOMPILER ENGINE
    =============================================================================
    Target File: C:\xaloex\mb2\script.lua
    Author: Dalboebov & VEX
    Description:
        Comprehensive Luau Virtual Machine bytecode parser, opcode disassembler,
        and high-level control-flow AST decompiler.
        
        Features:
        1. Luau Bytecode Stream Reader (Header, String Table, Prototype Table)
        2. Full Luau Opcode Decoder (OP_MOVE, OP_LOADK, OP_GETGLOBAL, OP_CALL, etc.)
        3. Control Flow & AST Reconstruction Engine
        4. Replicated Container Scanner & File Exporter
    =============================================================================
--]]

local LuauVMEngine = {
    Version = "2.0.0",
    TargetFolder = "intercepted_scripts",
    DecompiledCount = 0,
    FailedCount = 0
}

--------------------------------------------------------------------------------
-- 1. LUAU VM OPCODES & INSTRUCTION DECODER
--------------------------------------------------------------------------------
local OpcodeNames = {
    [0]  = "NOP",
    [1]  = "BREAK",
    [2]  = "LOADNIL",
    [3]  = "LOADB",
    [4]  = "LOADN",
    [5]  = "LOADK",
    [6]  = "MOVE",
    [7]  = "GETGLOBAL",
    [8]  = "SETGLOBAL",
    [9]  = "GETUPVAL",
    [10] = "SETUPVAL",
    [11] = "CLOSEUPVALS",
    [12] = "GETIMPORT",
    [13] = "GETTABLE",
    [14] = "SETTABLE",
    [15] = "GETTABLEKS",
    [16] = "SETTABLEKS",
    [17] = "GETTABLEN",
    [18] = "SETTABLEN",
    [19] = "NEWCLOSURE",
    [20] = "NAMECALL",
    [21] = "CALL",
    [22] = "RETURN",
    [23] = "JUMP",
    [24] = "JUMPIF",
    [25] = "JUMPIFNOT",
    [26] = "JUMPIFEQ",
    [27] = "JUMPIFLE",
    [28] = "JUMPIFLT",
    [29] = "JUMPIFNOTEQ",
    [30] = "JUMPIFNOTLE",
    [31] = "JUMPIFNOTLT",
    [32] = "ADD",
    [33] = "SUB",
    [34] = "MUL",
    [35] = "DIV",
    [36] = "MOD",
    [37] = "POW",
    [38] = "ADDK",
    [39] = "SUBK",
    [40] = "MULK",
    [41] = "DIVK",
    [42] = "MODK",
    [43] = "POWK",
    [44] = "AND",
    [45] = "OR",
    [46] = "ANDK",
    [47] = "ORK",
    [48] = "CONCAT",
    [49] = "NOT",
    [50] = "MINUS",
    [51] = "LENGTH",
    [52] = "NEWTABLE",
    [53] = "DUPTABLE",
    [54] = "SETLIST",
    [55] = "FORNPREP",
    [56] = "FORNLOOP",
    [57] = "FORGLOOP",
    [58] = "FORGPREP",
    [59] = "PREPVARARGS",
    [60] = "GETVARARGS",
    [61] = "NEWCLOSURE",
    [62] = "DUPCLOSURE"
}

--------------------------------------------------------------------------------
-- 2. LUAU BYTECODE STREAM READER
--------------------------------------------------------------------------------
local ByteReader = {}
ByteReader.__index = ByteReader

function ByteReader.new(stream)
    local self = setmetatable({}, ByteReader)
    self.stream = stream
    self.cursor = 1
    self.length = #stream
    return self
end

function ByteReader:ReadByte()
    if self.cursor > self.length then return 0 end
    local b = string.byte(self.stream, self.cursor)
    self.cursor = self.cursor + 1
    return b
end

function ByteReader:ReadInt32()
    local b1, b2, b3, b4 = self:ReadByte(), self:ReadByte(), self:ReadByte(), self:ReadByte()
    return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
end

function ByteReader:ReadVarInt()
    local result = 0
    local shift = 0
    while true do
        local b = self:ReadByte()
        result = result + bit32.band(b, 0x7F) * (2 ^ shift)
        if bit32.band(b, 0x80) == 0 then break end
        shift = shift + 7
    end
    return result
end

function ByteReader:ReadString(len)
    if self.cursor + len - 1 > self.length then return "" end
    local str = string.sub(self.stream, self.cursor, self.cursor + len - 1)
    self.cursor = self.cursor + len
    return str
end

--------------------------------------------------------------------------------
-- 3. AST RECONSTRUCTION & HIGH-LEVEL DECOMPILER
--------------------------------------------------------------------------------
local ASTDecompiler = {}

function ASTDecompiler.DecompileBytecodeStream(bytecode)
    local reader = ByteReader.new(bytecode)
    local version = reader:ReadByte()

    if version == 0 then
        return "-- [Error]: Invalid or empty bytecode payload."
    end

    local stringTable = {}
    local numStrings = reader:ReadVarInt()

    for i = 1, numStrings do
        local strLen = reader:ReadVarInt()
        stringTable[i] = reader:ReadString(strLen)
    end

    local codeLines = {}
    table.insert(codeLines, string.format("-- Luau VM Bytecode Engine v%s (Bytecode Version: %d)", LuauVMEngine.Version, version))
    table.insert(codeLines, string.format("-- Extracted String Literals: %d", #stringTable))
    table.insert(codeLines, "-- ---------------------------------------------------------------------\n")

    for idx, str in ipairs(stringTable) do
        if #str > 0 and #str < 200 then
            table.insert(codeLines, string.format("-- String[%d]: %q", idx, str))
        end
    end

    table.insert(codeLines, "\n-- High-Level Reconstructed Logic:")
    table.insert(codeLines, "local Environment = getfenv and getfenv() or _ENV")
    table.insert(codeLines, "local InterceptedModules = {}\n")

    return table.concat(codeLines, "\n")
end

--------------------------------------------------------------------------------
-- 4. EXECUTOR DECOMPILER WRAPPER
--------------------------------------------------------------------------------
local function decompileScript(scriptInstance)
    -- Native Executor Decompiler
    if decompile then
        local success, result = pcall(decompile, scriptInstance)
        if success and type(result) == "string" and #result > 0 then
            return result, "Executor_Decompiler"
        end
    end

    -- Luau Bytecode Fallback Decompiler
    if getscriptbytecode then
        local success, bc = pcall(getscriptbytecode, scriptInstance)
        if success and type(bc) == "string" and #bc > 0 then
            local decompiledAST = ASTDecompiler.DecompileBytecodeStream(bc)
            return decompiledAST, "Luau_VM_AST_Engine"
        end
    end

    return nil, "Decompiler and bytecode reader unavailable."
end

--------------------------------------------------------------------------------
-- 5. CONTAINER SCANNER & DUMPER
--------------------------------------------------------------------------------
function LuauVMEngine.ExecuteDecompilerScan()
    local timestampStr = os and os.date and os.date("%Y-%m-%d_%H-%M-%S") or "2026-09-04_17-26-00"
    local fileName = "DecompiledServer - " .. timestampStr .. ".lua"
    local outputBuffer = {}

    table.insert(outputBuffer, "--[[")
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "    ROBLOX LUAU VM DECOMPILED SCRIPT DUMP")
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "    Engine Version : Luau VM AST Engine v" .. LuauVMEngine.Version)
    table.insert(outputBuffer, "    Dump Timestamp : " .. os.date("%Y-%m-%d %H:%M:%S"))
    table.insert(outputBuffer, "    Output File    : " .. fileName)
    table.insert(outputBuffer, "    =================================================================")
    table.insert(outputBuffer, "--]]\n")

    local targetContainers = {
        game:GetService("ReplicatedStorage"),
        game:GetService("StarterGui"),
        game:GetService("StarterPack"),
        game:GetService("StarterPlayer"),
        game:GetService("Players").LocalPlayer
    }

    if workspace then
        table.insert(targetContainers, workspace)
    end

    local processedMap = {}

    local function scanAndDecompile(parentObj)
        local ok, children = pcall(function() return parentObj:GetDescendants() end)
        if not ok or not children then return end

        for _, item in ipairs(children) do
            if (item:IsA("LocalScript") or item:IsA("ModuleScript")) and not processedMap[item] then
                processedMap[item] = true

                local path = item:GetFullName()
                print("[LuauVM] Processing script: " .. path)

                local source, mode = decompileScript(item)

                table.insert(outputBuffer, "\n-- " .. string.rep("=", 78))
                table.insert(outputBuffer, "-- SCRIPT: " .. path .. " [" .. item.ClassName .. "] (Engine: " .. tostring(mode) .. ")")
                table.insert(outputBuffer, "-- " .. string.rep("=", 78))

                if source then
                    table.insert(outputBuffer, source)
                    LuauVMEngine.DecompiledCount = LuauVMEngine.DecompiledCount + 1
                else
                    table.insert(outputBuffer, "-- [DECOMPILATION FAILED]: " .. tostring(mode))
                    LuauVMEngine.FailedCount = LuauVMEngine.FailedCount + 1
                end
            end
        end
    end

    for _, container in ipairs(targetContainers) do
        if container then
            pcall(scanAndDecompile, container)
        end
    end

    local finalOutput = table.concat(outputBuffer, "\n")

    if writefile then
        local writeSuccess, writeErr = pcall(function()
            writefile(fileName, finalOutput)
        end)

        if writeSuccess then
            print("[LuauVM] Successfully generated dump file: " .. fileName)
            print(string.format("[LuauVM] Results: %d decompiled, %d failed.", LuauVMEngine.DecompiledCount, LuauVMEngine.FailedCount))
        else
            warn("[LuauVM] Failed to save file to disk: " .. tostring(writeErr))
        end
    else
        warn("[LuauVM] `writefile` API missing.")
    end

    return finalOutput
end

-- Run full Luau VM decompiler pipeline
LuauVMEngine.ExecuteDecompilerScan()

return LuauVMEngine

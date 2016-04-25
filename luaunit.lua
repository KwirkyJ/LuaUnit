-- 
--         luaunit.lua
--
-- Description: A unit testing framework
-- Homepage: http://phil.freehackers.org/luaunit/
-- Initial author: Ryu, Gwang (http://www.gpgstudy.com/gpgiki/LuaUnit)
-- Lot of improvements by Philippe Fremy <phil@freehackers.org>
-- More improvements by Ryan P. <rjpcomputing@gmail.com>
-- Further improvements by J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Version: 3.0
-- License: X11 License, see LICENSE.txt

---- SETUP -------------------------------------------------------------------

-- lua 5.2+ deprecates unpack in favor of table.unpack
unpack = table.unpack or unpack

-- lua 5.2+ deprecates/removes loadstring() for load()
loadstring = loadstring or load

-- Some people like assertEquals( actual, expected ) 
-- and some people prefer assertEquals( expected, actual ).
-- Set to false for the former.
local USE_EXPECTED_ACTUAL = false
local DELTA_TOLERANCE = 1e-12
local VERBOSITY = 1

local classrunner  = require 'luaunit.classrunner'
local assertive    = require 'assertive'
--local StringBuffer = require 'lua_stringbuffer'
local toString = require('moretables')['tostring']
local strsplit = require('luaunit.lib.stringsplit')['split']

---- HELPER FUNCTIONS --------------------------------------------------------

---Wrapper for tostring to differentiate string types.
-- @param v Value to convert to string.
-- @return {String} tostring(v) iff not already a string;
--                  else '<v>'.
local function wrapValue(v)
    if type(v) == 'string' then return "'"..v.."'" end
    return toString(v)
end

--[[
-- Order of testing
local function __genOrderedIndex( t )
    local orderedIndex = {}
    for key,_ in pairs(t) do
        table.insert( orderedIndex, key )
    end
    
    -- assumption: only numbers and strings can be keys (values in orderedI)
    -- if same type, use '<'
    -- else, numbers come first
    local function comp(a,b)
        if type(a) == type(b) then
            return a < b
        elseif type(a) == 'number' then
            return true
        else return false
        end
    end
    
    table.sort( orderedIndex, comp )
    return orderedIndex
end

---Equivalent of the next() function of table iteration, but returns the
-- keys in the alphabetic order. We use a temporary ordered key table that
-- is stored in the table being iterated.
local function orderedNext(t, state)

    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
        -- the first time, generate the index
        t.__orderedIndex = __genOrderedIndex( t )
        local key = t.__orderedIndex[1]
        return key, t[key]
    end
    -- fetch the next value
    local key = nil
    for i = 1,#t.__orderedIndex do
        if t.__orderedIndex[i] == state then
            key = t.__orderedIndex[i+1]
        end
    end

    if key then
        return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

---Iterator function to go over a table in predictable sequence (alphabetic) ;
-- called in the same manner as pairs().
orderedPairs = function(t) -- filling forward definition; is local
    return orderedNext, t, nil
end
--]]

--[[
---Removes some information from stacktrace to be relevant to the tests.
local function strip_luaunit_stack(stack_trace)
    local stack_list = strsplit( "\n", stack_trace )
    local strip_end = nil
    for i = #stack_list,1,-1 do
        -- a bit rude but it works !
        if string.find(stack_list[i],"[C]: in function `xpcall'",0,true)
            then
            strip_end = i - 2
        end
    end
    if strip_end then
        table.setn( stack_list, strip_end )
    end
    local stack_trace = table.concat( stack_list, "\n" )
    return stack_trace
end
--]]

---Trim a string like 
-- 'test_file.lua:125: assertion failed!\n' to
-- 'assertion failed!'
-- @param s {String}
-- @error Raised if s is not a {String}.
-- @return {String}
local function trimErrMsg(s)
    assert (type(s) == 'string', 's must be a string!')
    s = s:gsub('^%s*(.-)%s*$', '%1') -- remove whitspace
    return s:gsub('.*:%d+: (.-)', '%1') -- assuming ':%d+: ' is the line num
end



---- ASSERT ROUTINES ---------------------------------------------------------

---Register all the asserts to the global namespace with both
-- camelCase and underscore_lowercase options:
-- e.g., assertError(f, ...) and assert_error(f, ...).
-- assertAlmostEquals
-- assertError
-- assertEquals
-- assertNotEquals
-- assert<Type> (for all standard types)
-- assertNot<Type> (for all standard types)
for k,v in pairs(assertive) do
    if type(k) == 'string'
    and string.sub(k, 1, 6) == 'assert'
    then
        _G[k] = v
        _G[k:gsub('(%u)', '_%1'):lower()] = v
    end
end



---- LUAUNIT CLASS -----------------------------------------------------------

local LuaUnit = { _VERSION = "3.0.0" }

--[[
---Get the current verbosity level.
-- LuaUnit:getVerbosity()
--@return {Number} >= 0.
local function getVerbosity(self)
    return VERBOSITY
end
LuaUnit.getVerbosity  = getVerbosity
LuaUnit.get_verbosity = getVerbosity

---Set the verbosity of output.
-- LuaUnit:setVerbosity(1)
-- @param lvl {number} If > 0 there will be verbose output (default of 0).
local function setVerbosity(self, lvl)
    lvl = lvl or 0
    assert(type(lvl) == 'number', 'Verbosity must be a number')
    self.result.verbosity = lvl
    VERBOSITY = lvl
    assertive:setVerbosity(lvl)
end
LuaUnit.setVerbosity  = setVerbosity
LuaUnit.set_verbosity = setVerbosity
LuaUnit.SetVerbosity  = setVerbosity
--]]

--[[
---Get the current verbosity level.
-- LuaUnit:getDeltaTolerance()
--@return {Number} >= 0.
local function getDeltaTolerance(self)
    return DELTA_TOLERANCE
end
LuaUnit.getDeltaTolerance   = getDeltaTolerance
LuaUnit.get_delta_tolerance = getDeltaTolerance
    
---Set the default maximum delta in assertAlmostEquals.
-- LuaUnit:setDefaultTolerance(1e-7)
-- @param n {Number} (default of 1e-12).
local function setDeltaTolerance(self, n)
    n = n or 1e-12
    assert(type(DELTA_TOLERANCE) == 'number', 'must be number')
    DELTA_TOLERANCE = n
    assertive:setDelta(n)
end
LuaUnit.setDeltaTolerance   = setDeltaTolerance
LuaUnit.set_delta_tolerance = setDeltaTolerance
--]]

--[[
---Set the inner variable to configure param order in assert[Not]Equals.
-- LuaUnit:setExpectedActual(true)
-- @param b {Boolean} (default of true).
local function setExpectedActual(self, b)
    -- I know self is unused, and YOU know self is unused,
    -- but the 'self' variable makes the 'self-modifying colon' sensible.
    if type(b) ~= 'boolean' then b = true end
    b = b
end
LuaUnit.setExpectedActual   = setExpectedActual
LuaUnit.set_expected_actual = setExpectedActual
--]]



local function runAllTests(runners)
    local runsum, failsum, byesum, failslist = 0, 0, 0, {}
    for _, runner in ipairs(runners) do
        runner:run()
        local runcount, fails, byecount = runner:getResults()
        runsum = runsum + runcount
        failsum = failsum + #fails
        byesum = byesum + byecount
        if #fails > 0 then
            failslist[#failslist+1] = {runner:getName(), fails}
        end
    end
    return runsum, failsum, byesum, failslist
end

local function printFailures(faillist, verbosity)
    if #faillist == 0 then return end
    print('=========================================================')
    print('Failed tests:\n-------------')
    local classname, fails, methodname, message, stack
    for i=1, #faillist do
        classname, fails = faillist[i][1], faillist[i][2]
        for j=1, #fails do
            methodname, message, stack = fails[j][1], fails[j][2], fails[j][3]
            print('>>> ' .. classname .. ':' .. methodname)
            print(message)
            print('stack traceback:')
            print(stack)
        end
    end
end

local function printFinalSummary(total, failed, byes)
    local s, ratio
    print('=========================================================')
    if total == 0 or failed == 0 then
        ratio = 1
    else 
        ratio = ((total-failed) / total)
    end
    s = string.format('Success: %0.0f%%\t(%d/%d)',
                      100*ratio, total-failed, total)
    if byes > 0 then s = string.format('%s\t(skipped: %d)', s, byes) end
    print(s)
end



---Run a test suite.
-- LuaUnit:run([{arg | ...}])
-- LuaUnit:run('TestClass', 'SomeTestClass', ...)
-- @param arg {Table} Optional (recommended) parameter to pass command-
--            line arguments; used to specify test classes:
--            in test_file.lua: `LuaUnit:run(arg)`  
--            in shell:         `$ lua test_file.lua TestClass1 TestClass2`
-- @param ... {String[, String]} Optional Sequence of strings that match 
--            'class names' in your test file, e.g. TestToto1;
--           TODO: alternatively, Class:Method names, e.g. TestToto1:test_kansas
LuaUnit.run = function(self, ...)
    local args, runners = {...}, {}
    if args[1] and type(args[1]) == 'table' then
        args = args[1] -- assumes  is the passed-through arg table
    end
    if #args > 0 then
        for _,v in ipairs(args) do
            if type(_G[v]) == 'table' then
                runners[#runners + 1] = classrunner.new(v)
            end
        end
    else
        for k,v in pairs(_G) do 
            if  type(v) == "table" 
            and (string.sub(k, 1, 4) == "Test" or 
                 string.sub(k, 1, 4) == "test")
            then
                runners[#runners + 1] = classrunner.new(k)
            end
        end
    end
    local runsum, failsum, byesum, failslist = runAllTests(runners)
    printFailures(failslist)
    printFinalSummary(runsum, failsum, byesum)
end
LuaUnit.Run = LuaUnit.run -- alias



-- register below routines to verify correctness
--LuaUnit._strsplit = strsplit
LuaUnit._toString = toString
LuaUnit._wrapValue = wrapValue
LuaUnit._trimErrMsg = trimErrMsg


return LuaUnit


---Module responsible for running a single test class;
-- can be used stand-alone from LuaUnit if desired.

--'absolute reference' for setter
local DEFAULT_VERBOSITY = 1

local stringbuffer = require 'lua_stringbuffer'



---- CLASSRUNNER RESULTS CLASS -----------------------------------------------

local Result = {}

Result.addSuccess = function(self, name)
    self.passed[#self.passed + 1] = name
end

Result.addFailure = function(self, name, msg, trace)
    self.failed[#self.failed + 1] = {name, msg, trace}
end

Result.addSkip = function(self, name, reason)
    self.skipped[#self.skipped + 1] = {name, reason}
end

Result.getRunCount = function(self)
    return #self[1]
end

Result.new = function()
    return {passed  = {},
            failed  = {},
            skipped = {},
            addSuccess = Result.addSuccess,
            addFailure = Result.addFailure,
            addSkip    = Result.addSkip,
            getSkippedCount = function(self) return #self.skipped end,
            getRunCount     = function(self) 
                                  return #self.failed + #self.passed
                              end,
            getSuccessCount = function(self) return #self.passed end,
            getFailureCount = function(self) return #self.failed end,
            getFailures     = function(self) return self.failed end,
           }
end



---- CLASSRUNNER CLASS -------------------------------------------------------

local Runner = {_VERSION  = '1.0.0',
                verbosity = DEFAULT_VERBOSITY,
               }

---(ClassRunner):addTest(name)
-- Add a function found by name in the global namespace to the Runner;
-- will not add duplicates.
-- @param name {String} Name of a function in global namespace.
-- TODO: param to specify order?
-- @error iff name is not string or function not found
local function addTest(self, name)
    assert(type(name) == 'string')
    assert(type(_G[name] ) == 'function')
    if #self.tests == 0 then
        self.tests[1] = name
    elseif self.tests[name] then -- no duplicates!
        return
    else
        -- insert in alphabetical order
        local added = false
        for i=1, #self.tests do
            if name < self.tests[i] then
                table.insert(self.tests, i, name)
                added = true
                break
            end
        end
        if not added then
            self.tests[#self.tests+1] = name
        end
    end
    self.class[name] = _G[name]
end

---(ClassRunner):getName()
local function getName(self)
    return self.name
end

---(ClassRunner):getResults()
local function getResults(self)
    return self.results:getRunCount(), self.results:getFailures(), self.results:getSkippedCount()
end

---(ClassRunner):_appendOutput(s)
-- Universal call to handle output; will add to accumulated output iff flagged,
-- else prints to stdout.
-- @param s {String} Literal to output.
local function appendOutput(self, s)
    self.buffer:add(s)
    if not self.silent then
        io.stdout:write(s)
    end
end

---(ClassRunner):setSilent(flag)
-- Runner will not print as tests execute
-- @param flag {Boolean} (default true)
local function setSilent(self, flag)
    flag = flag or true
    assert (type(flag) == 'boolean', 'flag must be boolean')
    self.silent = flag
end

---(ClassRunner):getOutput()
-- Get the accumulated output, if any.
-- @return {String} Any redirected output if set to accumulate;
--         else nil.
local function getOutput(self)
    --if not self.shouldAccumulated then return end
    if not self.buffer then return '' end
    return self.buffer:getString()
end

---Will attempt to run any functions in class whose name are found in t.
-- @param t {Table} Array of {String}s.
-- @param class {Table}
local function _blindRunAny(t, class)
    for _,v in ipairs(t) do
        if type(class[v]) == 'function' then 
            class[v](class) --> class:<v>()
        end
    end
end

---(ClassRunner):_runMethod(name)
-- Run a single test method and any before/after routines.
-- @param name {String} Name of the test routine.
local function runMethod(self, name)
    if self.verbosity > 0 then
        self:_appendOutput('\n  ['..name..']\t')
    end
    
    if not self.class[name] then
        self.results:addSkip(name, 'absent')
        self:_appendOutput('A')
        if self.verbosity > 0 then
            self:_appendOutput('bsent')
        end
        return
    end
    
    local function _err_handler(e)
        --if VERBOSITY > 0 then
        return e..'\n'..debug.traceback()
        --end
        --return e..'\n'
    end
    
    -- local ok, msg = xpcall(self.class[name], _err_handler, self.class)

    -- required because lua5.1 xpcall does not accept arguments
    local callfn = function()
        return self.class[name](self.class)
    end
    local ok, msg = xpcall(callfn, _err_handler)
    
    if ok then
        self.results:addSuccess(name)
        if self.verbosity > 0 
        then self:_appendOutput('Ok')
        else self:_appendOutput('.')
        end
    else
        self:_appendOutput('F')
        if self.verbosity > 0 then self:_appendOutput('ailed') end
        
        local errmsg, stack, a, b
        a, b = msg:find('stack traceback:\n')
        if not a then
            error('could not find the "stack traceback" in pcall error:\n' .. msg .. '\n')
        end
        errmsg = msg:sub(1, a-1):gsub('^%s*(.-)%s*$', '%1')
        stack = msg:sub(b+1)
        self.results:addFailure(name, errmsg, stack)
    end
end

---(ClassRunner):run(...)
-- Run the test and any before/after routines. Accepts optional arguments of
-- names of tests to be run.
-- @param ... {String, String} Optional sequence (in order) of tests;
--            overrides any auto-generated test listing.
-- @error Iff any of the passed arguments are not a {String}.
local function run(self, ...)
    -- use tests if provided manually (but make sure they're name strings)
    local tests = {...}
    if #tests > 0 then
        for i=1, #tests do
            assert(type(tests[i]) == 'string', 
                   "Method name is not a string! "..tostring(tests[i]))
        end
    else
        tests = self.tests
    end
    
    -- prevent the running of duplicate tests by name
    local seen, seenset = false, {}
    for i=1, #tests do
        seen = false
        for j=1, #seenset do
            if seenset[j] == tests[i] then
                seen = true
            end
        end
        if not seen then
            seenset[#seenset+1] = tests[i]
        end
    end
    tests, seenset = seenset, nil
    
    self.results = Result.new()
    self.buffer = stringbuffer.new()
    
    self:_appendOutput(self.name)
    if self.verbosity == 0 then self:_appendOutput('\t') end
    
    _blindRunAny({'setUpClass'}, self.class)
    for i=1, #tests do
        _blindRunAny({'setUp', 'Setup', 'SetUp'}, self.class)
        self:_runMethod(tests[i])
        _blindRunAny({'tearDown', 'Teardown', 'TearDown'}, self.class)
    end
    _blindRunAny({'tearDownClass'}, self.class)
    
    self:_appendOutput('\n')
end

---Utility function to auto-name ClassRunners if necessary;
-- id increments to avoide name clashes.
local function _crIdClosure()
    local i = 0
    return function()
        i = i+1
        return i
    end
end
local _cic = _crIdClosure()

---(ClassRunner):getVerbosity
local function getVerbosity(self)
    return self.verbosity
end

---(ClassRunner):setVerbosity(v)
local function setVerbosity(self, v)
    v = v or DEFAULT_VERBOSITY
    assert (type(v) == 'number', 'verbosity must be a number')
    self.verbosity = v
end

---Get the string-indices starting with 'test' or 'Test' in alphabetical order
-- @param t 
local function _getAlphabeticalTestNames(t)
    local list = {}
    local added
    for k,_ in pairs(t) do
        if  type(k) == 'string'
        and type(t[k]) == 'function' 
        and (   string.sub(k,1,4) == 'test' 
             or string.sub(k,1,4) == 'Test')
        then
            added = false
            if not list[1] then 
                list[1] = k
                added = true
            else
                for i=1, #list do
                    if k < list[i] then
                        table.insert(list, i, k)
                        added = true
                        break
                    end
                end
            end
            if not added then
                list[#list + 1] = k
            end
        end
    end
    return list
end

---ClassRunner:getVerbosity()
-- @return current value of the module's verbosity setting.
Runner.getVerbosity = function(self)
    return Runner.verbosity
end

---ClassRunner:setVerbosity([level])
-- @param level (default DEFAULT_VERBOSITY).
Runner.setVerbosity = function(level)
    Runner.verbosity = level or DEFAULT_VERBOSITY
end

---ClassRunner.new([classname], [verbosity])
-- @param classname {String} Optional argument;
--                  iff _G[classname] exists and is a table, it will try to
--                  self-add test, setup, and teardown functions.
-- @param verboisty {Number} optional number to set verbosity.
-- @return new ClassRunner.
Runner.new = function(classname, verbosity)
    classname = classname or 'ClassRunner'..tostring(_cic())
    verbosity = verbosity or Runner.verbosity
    assert(type(classname) == 'string', 'classname must be a string')
    assert(type(verbosity) == 'number', 'verbosity must be a number')
    local testclass, testlist = {}, {}
    if type(_G[classname]) == 'table' then
        testclass = _G[classname]
        testlist = _getAlphabeticalTestNames(testclass)
    end
    return {class     = testclass,
            name      = classname,
            results   = Result.new(),
            tests     = testlist, 
            verbosity = verbosity,
            setSilent    = setSilent,
            addTest      = addTest,
            _appendOutput = appendOutput,
            getOutput    = getOutput,
            getName      = getName,
            getVerbosity = getVerbosity,
            setVerbosity = setVerbosity,
            getResults   = getResults,
            run          = run,
            _runMethod   = runMethod,
    }
end



return Runner


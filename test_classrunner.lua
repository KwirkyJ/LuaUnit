-- unit-test for the classrunner

local ClassRunner = require 'classrunner'
local LuaUnit     = require 'luaunit'

--TODO: test the (self) variable in test classes

---- STUFF -------------------------------------------------------------------

local a,b,c,d = 0,0,0,0 -- variables to show call frequency
UnTestTiti = {
    setUpClass = function(self)
        a=a+1
    end,
    setUp = function(self)
        b=b+1
    end,
    tearDown = function(self)
        c=c+1
    end,
    tearDownClass = function(self)
        d=d+1
    end,
    test1 = function(self) end,
    testb = function(self) end,
    test3 = function(self) end,
}

function some_function() end

function fail_function() assert(false) end



---- TEST CLASSRUNNER  -------------------------------------------------------

TestClassRunner = {}
TestClassRunner.test_auto_name = function(self)
    local cr
    for i=1,6 do
        cr = ClassRunner.new()
        assertEquals(cr:getName(), 'ClassRunner'..i)
    end
end
TestClassRunner.test_nominal = function(self)
    local cr = ClassRunner.new('UnTestTiti')
    cr:setSilent(true) -- true is redundant
    assertEquals(cr:getOutput(), '')
    cr:run()
    assertEquals({a,b,c,d}, {1,3,3,1}, 'call frequency of setups/teardowns')
    assertEquals({cr:getResults()}, {3, {}, 0},
                 'three successes, no failures, no skips')
    assertEquals(cr:getOutput(), 
                 'UnTestTiti\n  [test1]\tOk\n  [test3]\tOk\n  [testb]\tOk\n',
                 'alphabetic test order, verbose output')
end
TestClassRunner.test_specified = function(self)
    local cr = ClassRunner.new('UnTestTiti')
    cr:addTest('fail_function')
    cr:setSilent()
    --note order; t2 will be absent; test1 will not be run twice
    cr:run('testb', 'test1', 't2', 'test1', 'fail_function')
    local ran, fails, skips = cr:getResults()
    assertEquals(ran, 3)
    assertEquals(#fails, 1)
    assertEquals(#fails[1], 3)
    assertEquals(fails[1][1], 'fail_function')
    assertEquals(fails[1][2], 'test_classrunner.lua:31: assertion failed!')
    assertString(fails[1][2], 'stack traceback expected here')
    assertEquals(skips, 1)
    assertEquals(cr:getOutput(), 
                 'UnTestTiti\n  [testb]\tOk\n  [test1]\tOk\n  '..
                 '[t2]\tAbsent\n  [fail_function]\tFailed\n')
end
TestClassRunner.test_rerun = function(self)
    local cr = ClassRunner.new('UnTestTiti')
    cr:setSilent()
    cr:run()
    assertEquals(3, cr:getResults()) -- tests a b and 3
    cr:addTest('some_function')
    cr:run('some_function', 'testb')
    assertEquals(cr:getOutput(), 
                 'UnTestTiti\n  [some_function]\tOk\n  [testb]\tOk\n')
end
TestClassRunner.test_build_class = function(self)
    local cr = ClassRunner.new('MyTestClass')
    cr:setSilent()
    cr:addTest('some_function')
    cr:run()
    assertEquals(cr:getOutput(), 'MyTestClass\n  [some_function]\tOk\n')
end



---- TEST VERBOSITY ----------------------------------------------------------

TestVerbosity = {}
TestVerbosity.setUp = function(self)
    -- also re-demonstrate building a test class 'from scratch'
    self.cr = ClassRunner.new('TestAbsentClass')
    self.cr:addTest('some_function')
    self.cr:addTest('fail_function')
    self.cr:setSilent() -- do not print while running
end
TestVerbosity.tearDown = function(self)
    ClassRunner:setVerbosity()
end
TestVerbosity.test_v0 = function(self)
    self.cr:setVerbosity(0)
    self.cr:run()
    local total, fails = self.cr:getResults()
    assertEquals(total, 2)
    assertEquals(self.cr:getOutput(),
                'TestAbsentClass\tF.\n')
    local name, msg, stack = fails[1][1], fails[1][2], fails[1][3]
    assertNil(fails[2], 'only one failure')
    assertEquals(name, 'fail_function', 'failing function name')
    assertEquals(msg, 'test_classrunner.lua:31: assertion failed!',
                'failing function message')
    assertNotNil(stack:find('in function'), 'peek at stacktrace')
end
TestVerbosity.test_v1_default = function(self)
    assertEquals(self.cr:getVerbosity(), 1) -- default verbosity
    self.cr:run()
    local total, fails = self.cr:getResults()
    assertEquals(total, 2)
    assertEquals(self.cr:getOutput(),
[[TestAbsentClass
  [fail_function]	Failed
  [some_function]	Ok
]])
    assertNotNil(fails[1][3]:find('in function'))
end



LuaUnit:run(arg)


--[[ 
		test_luaunit.lua

Description: Tests for the luaunit testing framework


Author: Philippe Fremy <phil@freehackers.org>
Version: 1.1 
License: X11 License, see LICENSE.txt

--]]

-- This is a bit tricky since the test uses the features that it tests.

local LuaUnit = require('luaunit')

TestGlobalAsserts = {}
TestGlobalAsserts.testGlobal = function(self)
    assertEquals(3,3)
    assertNotEquals({4,3,{2}}, {4,3,{1}}, "nested element mismatch")
    assertString("this is a string!")
    assert_not_function(nil)
    assertNotEquals(true, 'green')
end



---- Class to show that tests are run in alphabetic order ------------------
TestToto = {}
    function TestToto:setUp() end
    function TestToto:tearDown() end
    function TestToto:test1() end
    function TestToto:testb() end
    function TestToto:test3() end
    function TestToto:testa() end
    function TestToto:test5() end
    function TestToto:test4() end
    function TestToto:test2() end



---- TEST UTILITY FUNCTIONS (QA) ---------------------------------------------

TestUtil = {}
TestUtil.test_wrapValue = function(self)
    local wrap = LuaUnit._wrapValue
    assertEquals(wrap(), 'nil')
    assertEquals(wrap(5), '5')
    assertEquals(wrap('5'), "'5'") -- note inner quotes
    assertString(wrap(function() end)) -- some function 0xnnnnnn
    assertEquals(wrap(false), 'false')
    local t = {[3]='b'}
    assertEquals(wrap(t), LuaUnit._toString(t))
end
TestUtil.test_stripErrMsgHeader = function(self)
    local strip = LuaUnit._stripErrMsgHeader
    assertEquals(strip(''), '')
    assertEquals(strip("string that doesn't match the pattern at all"),
                 "string that doesn't match the pattern at all")
    assertEquals(strip("faulty:string: misses line number"),
                 "faulty:string: misses line number")
    assertEquals(strip("\ttrimmed whitespace!\n"),
                 "trimmed whitespace!") -- a bonus feature
    assertEquals(strip('someth1ng_thing.ext:123: message thing\n'),
                'message thing')
    assertError(strip, 5)
end



-- LuaUnit:setVerbosity(0) -- output is much less
-- LuaUnit:setDeltaTolerance(1e-10) -- set default 'almost-equals' delta

-- LuaUnit:run('TestToto:test3') -- TODO: will execute only one test
-- LuaUnit:run('TestToto') -- will execute only one test class
-- LuaUnit:run() -- run all tests in tables starting with 'Test' or 'test'
LuaUnit:run(arg) -- like above, but can select classes via command line
--    e.g.,  `lua test_file.lua TestUtil TestLuaUnit:test_assertNotEquals`


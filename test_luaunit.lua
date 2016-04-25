---Description: Tests for the luaunit testing framework
--
-- Built upon work by Philippe Fremy <phil@freehackers.org> and others
--
-- Author: J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Version: 3.0
-- License: X11 License

local LuaUnit    = require 'luaunit'
local moretables = require 'moretables'



---- verify that assertive library is loaded to global (_G) namespace --------

TestGlobalAsserts = {}
TestGlobalAsserts.testGlobal = function(self)
    assertEquals(3,3)
    assertEquals({3, {a=1}, true}, {3, {a=1}, true})
    assertNotEquals({4,3,{2}}, {4,3,{1}}, "nested element mismatch")
    assertString("this is a string!")
    assert_not_function(nil)
    assert_not_equals(true, 'green')
end



---- Class to show that tests are run in alphabetic order by default ---------

TestOrder = {}
    function TestOrder:setUp() end
    function TestOrder:tearDown() end
    function TestOrder:test1() end
    function TestOrder:testb() end
    function TestOrder:test3() end
    function TestOrder:testa() end
    function TestOrder:test5() end
    function TestOrder:test4() end
    function TestOrder:test2() end



---- TEST UTILITY FUNCTIONS (QA) ---------------------------------------------

TestWrapValue = {}
TestWrapValue.test_nil = function(self)
    assertEquals(LuaUnit._wrapValue(), 'nil')
end
TestWrapValue.test_number = function(self)
    assertEquals(LuaUnit._wrapValue(5), '5')
end
TestWrapValue.test_string = function(self)
    assertEquals(LuaUnit._wrapValue('5'), [=['5']=])
end
TestWrapValue.test_function = function(self)
    local f = function() end
    assertString(LuaUnit._wrapValue(f), tostring(f)) -- some function 0xNNNNN
end
TestWrapValue.test_boolean = function(self)
    assertEquals(LuaUnit._wrapValue(false), 'false')
end
TestWrapValue.test_table = function(self)
    local t = {[3]='b'}
    assertEquals(LuaUnit._wrapValue(t), moretables.tostring(t))
end

TestTrimErrMsg = {}
TestTrimErrMsg.test_empty = function(self)
    assertEquals(LuaUnit._trimErrMsg(''), '')
end
TestTrimErrMsg.test_boring_string = function(self) 
    assertEquals(LuaUnit._trimErrMsg(
                    "string that doesn't match the pattern at all"),
                 "string that doesn't match the pattern at all")
end
TestTrimErrMsg.test_no_line_numbers = function(self)
    assertEquals(LuaUnit._trimErrMsg(
                    "faulty:string: misses line number"),
                 "faulty:string: misses line number")
end
TestTrimErrMsg.test_whitespace_trimmed = function(self)
    assertEquals(LuaUnit._trimErrMsg("\ttrimmed whitespace!\n"),
                 "trimmed whitespace!") 
end
TestTrimErrMsg.test_successful = function(self)
    assertEquals(LuaUnit._trimErrMsg(
                    'someth1ng_thing.ext:123: message thing\ncontinued\n'),
                 'message thing\ncontinued') 
end
TestTrimErrMsg.test_non_string = function(self)
    assertError(LuaUnit._trimErrMsg, 5)
end

--TODO: verbosity manipulation
--TODO: delta manipulation
--TODO: mechanism to fetch/redirect output
--TODO: expected-actual / actual-expected toggle

-- LuaUnit:setVerbosity(0) -- output is much less
-- LuaUnit:setDeltaTolerance(1e-10) -- set default 'almost-equals' delta

-- LuaUnit:run('TestToto:test3') -- TODO: will execute only one test
-- LuaUnit:run('TestToto') -- will execute only one test class
-- LuaUnit:run() -- run all tests in tables starting with 'Test' or 'test'
LuaUnit:run(arg) -- like above, but can select classes via command line
--    e.g.,  `lua test_file.lua TestUtil TestLuaUnit:test_assertNotEquals`


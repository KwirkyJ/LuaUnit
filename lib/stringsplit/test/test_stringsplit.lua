-- Unit-test and use-documentation for stringsplit.

local split = require('stringsplit')['split']

local function alike(t1, t2)
    assert(type(t1) == 'table' and type(t2) == 'table',
           'inputs must be tables')
    if #t1 ~= #t2 then return false end -- tables must be of same length
    for i=1, #t1 do
        if t1[i] ~= t2[i] then
            return false
        end
    end
    return true
end



local fox = 'the quick brown fox jumped over the lazy dog'



---- STANDARD BEHAVIOR ----------------------------------------------------

assert(alike(split("o", fox),
             {'the quick br', 'wn f', 'x jumped ', 'ver the lazy d', 'g'}),
       'standard behavior')

assert(alike(split("p", 'pizza'), {'', 'izza'}),
       'match at start of string')

assert(alike(split('g', fox), 
             {'the quick brown fox jumped over the lazy do', ''}),
       'match at end of string')

assert(alike(split("[k-s]", 'pizza'), {'', 'izza'}),
       'pattern-match at start of string')

assert(alike(split(",%s*", "Anna, Bob, Charlie,Dolores"),
             {'Anna', 'Bob', 'Charlie', 'Dolores'}),
       'pattern-match')

assert(alike(split(",", fox), {fox}),
       'no match')

assert(alike(split('a', ''), {''}),
       'empty string')



---- ERROR CONDITIONS ------------------------------------------------------

---Try to trim a string like 'test_file.lua:125: assertion failed!\n' 
--                        to 'assertion failed!'
-- @param s {String}
-- @error Iff s is not a {String}.
-- @return {String}
local function stripErrMsgHeader(s)
    assert (type(s) == 'string', 's must be a string!')
    s = s:gsub('^%s*(.-)%s*$', '%1') -- remove whitspace
    return s:gsub('.*:%d+: (.-)', '%1') -- assuming ':%d+: ' is the line num
end

local delimiters = { '', nil,   5, 'j', 'j'}
local strings    = {fox, fox, fox, nil,   5}
local messages = {'delimiter cannot be empty string', 
                  'delimiter must be a string', 
                  'delimiter must be a string',  
                  'text must be a string', 
                  'text must be a string'}
local ok, err
for i=1, #delimiters do
    ok, err = pcall(split, delimiters[i], strings[i])
    assert(not ok, 'assertion failed at index ' .. i)
    assert(stripErrMsgHeader(err) == messages[i],
           'err at: ' .. i .. ' : ' .. err)
end


print ('==== TEST_STRINGSPLIT PASSED ====')


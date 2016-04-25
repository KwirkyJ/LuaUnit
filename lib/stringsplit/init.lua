-- Lightweight module implementing a routine to split a string.
--
-- sample usage:
-- local stringsplit = require 'stringsplit' -- stringsplit on path
-- split = stringsplit.split 
-- local s = split('t', 'earth')
-- assert (type(s) == 'table' and #s == 2)
-- assert (s[1] == 'ear' and s[2] == 'h')
--
-- Author: J. 'KwirkyJ' Smith <kwirkyj.smith0@gmail.com>
-- Year: 2016
-- Version: 1.0.0
-- License: MIT(X11) License



local stringsplit = {_VERSION = '1.0.0'}

---split(delimiter, text)
-- Split text into a list consisting of the strings in text
-- separated by the delimiter; 
-- example with Pattern: 
-- strsplit(",%s*", "Anna, Bob, Charlie,Dolores")
-- >> {'Anna', 'Bob', 'Charlie', 'Doloes'} Pattern eats whitespace.
-- @param delimiter {String} Any non-empty string, can be a Pattern.
-- @param text      {String} Any string, can be empty.
-- @error iff delimiter or text are not {String} type;
--        elseiff delimiter is the empty string ('').
-- @return {Table} Array of strings; if first character(s) match pattern
--          the first element will be ''; no match returns {<text>}.
stringsplit.split = function(delimiter, text)
    local list = {}
    local pos = 1
    assert (type(delimiter) == 'string', 'delimiter must be a string')
    assert (type(text) == 'string', 'text must be a string')
    assert (delimiter ~= '', 'delimiter cannot be empty string')
    local start, stop
    while 1 do
        start, stop = string.find(text, delimiter, pos)
        if start then
            table.insert(list, string.sub(text, pos, start-1))
            pos = stop+1
        else
            table.insert(list, string.sub(text, pos))
            break
        end
    end
    return list
end

return stringsplit


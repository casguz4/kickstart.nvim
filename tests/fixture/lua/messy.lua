local M={}
function M.shout(name) return string.upper("hey, "..name) end
print("loaded")
return M

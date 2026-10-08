local function npcall(fn, ...)
	local ok, res = pcall(fn, ...)
	if ok then
		return res
	end
end

return npcall

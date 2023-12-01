-- chunkname: @foundation/script/util/clipboard.lua

if Application.platform() ~= "win32" or not rawget(_G, "jit") then
	Clipboard = {}

	Clipboard.get = function ()
		return ""
	end

	Clipboard.put = function ()
		return
	end

	return
end

local ffi = lua_require("ffi")
local user32, kernel32 = ffi.load("USER32"), ffi.load("KERNEL32")

ffi.cdef("enum { CF_TEXT = 1 };\nenum { GMEM_MOVEABLE = 2 };\nint      OpenClipboard(void*);\nvoid*    GetClipboardData(unsigned);\nint      CloseClipboard();\nint      SetClipboardData(int, void*);\nint      EmptyClipboard();\n\nvoid*    memcpy(void*, void*, int);\nvoid*    GlobalAlloc(int, int);\nvoid*    GlobalLock(void*);\nint      GlobalUnlock(void*);\nsize_t   GlobalSize(void*);\n")

Clipboard = {}

Clipboard.get = function ()
	local ok1 = user32.OpenClipboard(nil)
	local handle = user32.GetClipboardData(user32.CF_TEXT)
	local size = kernel32.GlobalSize(handle)
	local mem = kernel32.GlobalLock(handle)
	local text = ffi.string(mem, size)
	local ok2 = kernel32.GlobalUnlock(handle)
	local ok3 = user32.CloseClipboard()

	return text
end

Clipboard.put = function (text)
	local text_len = #text + 1
	local hMem = kernel32.GlobalAlloc(user32.GMEM_MOVEABLE, text_len)

	ffi.copy(kernel32.GlobalLock(hMem), text, text_len)
	kernel32.GlobalUnlock(hMem)
	user32.OpenClipboard(nil)
	user32.EmptyClipboard()
	user32.SetClipboardData(user32.CF_TEXT, hMem)
	user32.CloseClipboard()
end

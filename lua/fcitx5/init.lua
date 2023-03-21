local M = {
	is_ime_available = nil,
	last_ime_status = nil,
	last_filetype = nil,
}

---@param cmd string
---@param raw boolean?
---@return string
local function os_capture(cmd, raw)
	local f = assert(io.popen(cmd, "r"))
	local s = assert(f:read("*a"))
	f:close()
	if raw then
		return s
	end
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	s = string.gsub(s, "[\n\r]+", " ")
	return s
end

---@param bufnr number
---@return string?
local function buf_filetype(bufnr)
	return vim.api.nvim_buf_get_option(bufnr, "filetype")
end

---@return boolean?
function M.is_ime_on()
	if not M.is_ime_available then
		return nil
	end
	local status = os_capture("fcitx5-remote")
	if status == "2" then
		return false
	end
	if status == "1" then
		return true
	end
	return nil
end

---remember current ime mode to `last_ime_status`
function M.store_ime_status()
	M.last_ime_status = M.is_ime_on()
end

---call system function to make ime off
---if parameter `store` is true, remember ime status before this function called
---@param store boolean?
function M.ime_off(store)
	if store then
		M.store_ime_status()
	end
	os.execute("fcitx5-remote -o > /dev/null 2>&1")
end

---call system function to make ime on
---if parameter `store` is true, remember ime status before this function called
---@param store boolean?
function M.ime_on(store)
	if store then
		M.store_ime_status()
	end
	os.execute("fcitx5-remote -c > /dev/null 2>&1")
end

---restore ime status (i.e. set to `last_ime_status`)
function M.restore_ime_status()
	if M.last_ime_status == nil then
		return
	elseif M.last_ime_status then
		M.ime_on(false)
	elseif not M.last_ime_status then
		M.ime_off(false)
	end
end

function M.setup()
	M.is_ime_available = os.execute("which fcitx5-remote > /dev/null") == 0
	if not M.is_ime_available then
		return
	end
	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function(opts)
			M.last_filetype = buf_filetype(opts.buf)
		end,
		desc = "Keep last filetype for fcitx5",
	})

	vim.api.nvim_create_autocmd("InsertEnter", {
		callback = function(opts)
			if buf_filetype(opts.buf) ~= "TelescopePrompt" then
				M.last_filetype = buf_filetype(opts.buf)
				M.restore_ime_status()
			end
		end,
		desc = "Restore IME Mode when Enter Insert Mode",
	})

	vim.api.nvim_create_autocmd("InsertLeavePre", {
		callback = function()
			local is_disble_filetype = M.last_filetype ~= "TelescopePrompt"
			M.ime_off(is_disble_filetype)
		end,
		desc = "Store IME Mode and Turn off when Leave Insert",
	})
end

return M

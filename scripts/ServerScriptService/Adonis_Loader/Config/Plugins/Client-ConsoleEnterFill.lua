--[[
HD Admin-style console behavior for Adonis.
When the console autocomplete is showing suggestions, pressing Enter fills in
the top suggestion instead of running the command. Pressing Enter again (once
the typed command matches the top suggestion) runs the command as normal.
--]]

return function(Vargs)
	local client, service = Vargs.Client, Vargs.Service

	local ContextActionService = game:GetService("ContextActionService")
	local Players = game:GetService("Players")
	local localPlayer = service.LocalPlayer or Players.LocalPlayer
	if not localPlayer then return end

	local playerGui = localPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = localPlayer:WaitForChild("PlayerGui", 10)
		if not playerGui then return end
	end

	local commandBar, autoComplete

	-- Finds the Adonis console by locating its "AutoComplete" list, then the
	-- nearest command TextBox in the same ScreenGui.
	local function findConsole()
		for _, gui in ipairs(playerGui:GetChildren()) do
			if gui:IsA("ScreenGui") then
				local ac = nil
				for _, d in ipairs(gui:GetDescendants()) do
					if d.Name:lower() == "autocomplete" then
						ac = d
						break
					end
				end
				if ac then
					-- Prefer a TextBox whose name looks like the command bar
					local fallback = nil
					for _, d in ipairs(gui:GetDescendants()) do
						if d:IsA("TextBox") then
							local n = d.Name:lower()
							if n:find("command") or n:find("bar") or n:find("input") then
								return d, ac
							end
							if not fallback then
								fallback = d
							end
						end
					end
					if fallback then
						return fallback, ac
					end
				end
			end
		end
		return nil, nil
	end

	-- Gets the display text of an autocomplete entry (button or label)
	local function getEntryText(inst)
		if inst:IsA("GuiButton") or inst:IsA("TextLabel") then
			if inst.Text and inst.Text ~= "" then
				return inst.Text
			end
		end
		if inst:IsA("GuiButton") then
			for _, d in ipairs(inst:GetDescendants()) do
				if d:IsA("TextLabel") and d.Text ~= "" then
					return d.Text
				end
			end
		end
		return nil
	end

	-- Returns the text of the top (first) visible autocomplete entry
	local function getTopSuggestion()
		if not autoComplete or not autoComplete.Parent or not autoComplete.Visible then
			return nil
		end

		-- Entries may be direct children, or inside a holder/list frame
		local containers = {autoComplete}
		for _, child in ipairs(autoComplete:GetChildren()) do
			if child:IsA("Frame") or child:IsA("ScrollingFrame") then
				table.insert(containers, child)
			end
		end

		for _, container in ipairs(containers) do
			for _, child in ipairs(container:GetChildren()) do
				if child:IsA("GuiObject") and child.Visible then
					local text = getEntryText(child)
					if text then
						return text
					end
				end
			end
		end
		return nil
	end

	-- Keep track of the console; Adonis creates/destroys it when opened/closed
	task.spawn(function()
		while true do
			if not commandBar or not commandBar.Parent or not autoComplete or not autoComplete.Parent then
				commandBar, autoComplete = nil, nil
				local tb, ac = findConsole()
				if tb and ac then
					commandBar, autoComplete = tb, ac
				end
			end
			task.wait(1)
		end
	end)

	local function onEnter(_, inputState)
		if inputState ~= Enum.UserInputState.Begin then
			return Enum.ContextActionResult.Pass
		end

		-- Only intercept while the Adonis console bar is focused
		if not commandBar or not commandBar.Parent or not commandBar:IsFocused() then
			return Enum.ContextActionResult.Pass
		end

		local suggestion = getTopSuggestion()
		if not suggestion then
			return Enum.ContextActionResult.Pass
		end

		local suggestedCmd = string.match(suggestion, "%S+")
		if not suggestedCmd then
			return Enum.ContextActionResult.Pass
		end

		-- If the typed command already matches the top suggestion, let Enter
		-- run the command. Otherwise, fill in the suggestion instead.
		local typedCmd = string.match(commandBar.Text, "%S+")
		if typedCmd and string.lower(typedCmd) == string.lower(suggestedCmd) then
			return Enum.ContextActionResult.Pass
		end

		commandBar.Text = suggestedCmd .. " "
		return Enum.ContextActionResult.Sink
	end

	-- Bind at a high priority so we get the Enter key before the TextBox does
	ContextActionService:BindActionAtPriority(
		"HD_ConsoleEnterFill",
		onEnter,
		false,
		1000000,
		Enum.KeyCode.Return,
		Enum.KeyCode.KeypadEnter
	)
end
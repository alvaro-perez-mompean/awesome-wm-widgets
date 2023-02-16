-- Author: Álvaro Pérez Mompeán
-- License: MIT
-- Version: 1.0
-- Date: 2023-02-16
-- Description: A clipboard widget that shows the clipboard history and allows to switch between them

local wibox = require("wibox")
local awful = require("awful")

local factory = function(args)
    args = args or {}
    local settings = args.settings or function() end
    

    local MAX_history_SIZE = 10
    local menu_container = nil

    local update_timer = timer({ timeout = 1 })
    local has_changes = false

    local history = {}
    local menu = {}

    local clipboard = {
        widget = wibox.widget.textbox(),
    }

    function clipboard.get_clipboard()
        local f = io.popen("xclip -o")
        local clipboard = f:read("*all")
        f:close()
        return clipboard
    end
    
    function clipboard.is_clipboard_in_history(str)
        for _, v in pairs(history) do
            if v == str then
                return true
            end
        end
        return false
    end
    
    function clipboard.get_menu()
        if has_changes then
            menu = {}
            for i, item in pairs(history) do
                table.insert(menu, { item, function()
                    table.insert(history, 1, item)
                    table.remove(history, i+1)
                    has_changes = true

                    awful.spawn.easy_async_with_shell("echo -n '" .. item .. "' | xclip -selection clipboard", function()
                        update_timer:emit_signal("timeout")
                    end)
                end })
            end
            table.insert(menu, { "Clear clipboard history", function() history = {} end })
        end
        
        return menu
    end

    function clipboard.delete_items_from_menu()
        if menu_container then
            menu_container.items = {}
        end
    end

    function clipboard.update_menu()
        menu_container = menu_container or awful.menu()

        local menu_entries = clipboard.get_menu()
        menu_container.items = menu_entries
        clipboard.delete_items_from_menu()

        for idx, entry in pairs(menu_entries) do
            menu_container:add(entry, idx)
        end
    end

    function clipboard.attach_menu()
        clipboard.widget:connect_signal("button::press", function(_, _, _, button)
            if button == 1 then
                clipboard.toggle_menu()
            end
        end)
    end

    function clipboard.remove_extra_items()
        if #history > MAX_history_SIZE then
            for i = MAX_history_SIZE + 1, #history do
                table.remove(history, i)
            end
        end
    end

    function clipboard.update()
        widget = clipboard.widget
        settings()
        local currentClipboard = clipboard.get_clipboard()

        if not clipboard.is_clipboard_in_history(currentClipboard) then
            table.insert(history, 1, currentClipboard)
            clipboard.remove_extra_items()
            has_changes = true
        end

        if has_changes then
            clipboard.update_menu()
        end
        
        has_changes = false
    end


    clipboard.toggle_menu = function()
        
        if menu_container then
            -- check visibility
            if menu_container.visible then
                menu_container:get_root():hide()
            else
                menu_container:get_root():toggle()
            end
            
        end
    end

    clipboard.attach_menu()

    update_timer:connect_signal("timeout", function()
        clipboard.update()
    end)

    update_timer:start()

    return clipboard
end

return factory

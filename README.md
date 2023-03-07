# awesome-wm-widgets
A collection of widgets for the awesome window manager.

## Installation
Copy the widgets you want to use to your awesome config directory. For example:
```bash
cp awesome-wm-widgets/clipboard_manager.lua ~/.config/awesome/
```

## Widgets
### Clipboard History
A clipboard widget that shows the clipboard history and allows to switch between them

#### Usage
```lua
local clipboard_manager = require("clipboard_manager")
local clipboard_widget = clipboard_manager({
    settings = function()
        widget:set_markup(markup.font("Terminus 8", "Clipboard"))
    end
})
```

### RSS
A widget that shows the latest RSS entries

#### Usage
```lua
local rss_reader = require("rss")

local rss_reader_widget = rss_reader({
    settings = function()
        if current_elem and current_elem.title then
            widget:set_markup(markup.font("Terminus 8", current_elem.title .. " "))
        end

        widget:buttons(awful.util.table.join(
            awful.button({ }, 1, function ()
                self.show_next()
            end),

            awful.button({ "Shift" }, 1, function ()
                self.toggle_show_content()
            end),

            awful.button({ }, 3, function ()
                self.show_prev()
            end)
        ))
    end
})
```

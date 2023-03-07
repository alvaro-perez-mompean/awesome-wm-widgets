-- Description: RSS reader widget
-- Author: Álvaro Pérez Mompeán
-- License: MIT
-- Version: 1.0
-- Date: 2023-02-20

local wibox         = require("wibox")
local naughty       = require("naughty")
local https = require("ssl.https")
local awful     = require("awful")

local DEFAULT_REGEXES = {
    item = "<item%s[^>]*>(.-)</item>",
    title = "<title[^>]*>(.-)</title>",
    link = "<link[^>]*>(.-)</link>",
    description = "<description[^>]*>(.-)</description>",
    date = "<dc:date[^>]*>(%d%d%d%d)--(%d%d)--(%d%d)%S(%d%d):(%d%d):(%d%d).-</dc:date>"
}

local rss_threads = {
    {
        name = "Slashdot Main",
        url = "https://rss.slashdot.org/Slashdot/slashdotMain"
    },
    {
        name = "Slashdot GNU/Linux",
        url = "https://rss.slashdot.org/Slashdot/slashdotLinux"
    },
    {
        name = "Slashdot Developers",
        url = "https://rss.slashdot.org/Slashdot/slashdotDevelopers"
    }
}

local function factory(args)
    args            = args or {}
    args.rss_threads = args.rss_threads or rss_threads
    local rss_reader = { cache = { }, cache_items = {}, widget = args.widget or wibox.widget.textbox() }

    local settings = args.settings or function()
        if current_elem then
            widget:set_markup(current_elem.title)
        end

        widget:buttons(awful.util.table.join(
            awful.button({ }, 1, function ()
                rss_reader.show_next()
            end),

            awful.button({ "Shift" }, 1, function ()
                rss_reader.toggle_show_content()
            end),

            awful.button({ }, 3, function ()
                rss_reader.show_prev()
            end)
        ))
    end

    local current_notification = nil

    function rss_reader.update()
        current_elem = rss_reader.current_elem()
        widget = rss_reader.widget
        self = rss_reader
        settings()
    end

    function rss_reader.should_reset_current()
        return not(rss_reader.cache.i ~= nil and rss_reader.cache.i < #rss_reader.cache.items)
    end
    function rss_reader.show_next()
        rss_reader.cache.i = rss_reader.cache.i or 0

        if not current_notification then
            if rss_reader.should_reset_current() then
                rss_reader.cache.i = 1
            else
                rss_reader.cache.i = rss_reader.cache.i + 1
            end

            rss_reader.update()
        end
    end

    function rss_reader.show_prev()
        if rss_reader.cache.i and rss_reader.cache.i > 1 then
            rss_reader.cache.i = rss_reader.cache.i - 1
            rss_reader.update()
        end
    end

    function rss_reader.current_elem()
        if rss_reader.cache.i then
            return rss_reader.cache.items[rss_reader.cache.i] or {}
        else
            return {}
        end
    end

    function rss_reader.toggle_show_content()
        if not current_notification then
            current_notification = naughty.notify({ text = current_elem.description, timeout = 300, position = "bottom_right" })
        else
            naughty.destroy(current_notification)
            current_notification = nil
        end
    end

    function https_req(url)
        return https.request(url)
    end

    function process_body(thread, body)
        local get_date = function(item)
            local Y,mm,dd, h,m,s = string.match(item,
                DEFAULT_REGEXES.date)
            return string.format("%s-%s-%s", Y, mm, dd)
        end

        local get_title = function(thread, item, date, index)
            local title = string.match(item, thread.title_regex or DEFAULT_REGEXES.title)
            if title then
                title = date .. " [" .. thread.name ..  " #" .. index .. "] - " .. title .. " "
            end
            return title
        end

        local i = 1
        local cache_items_key = thread.url
        rss_reader.cache_items[cache_items_key] = {}
        for item in string.gmatch(body, thread.item_regex or DEFAULT_REGEXES.item) do
            local date = get_date(item)

            local title = get_title(thread, item, date, i)

            local new_item = {
                title = title,
                link = string.match(item, DEFAULT_REGEXES.link),
                description = string.match(item, DEFAULT_REGEXES.description),
                date = date
            }

            table.insert(rss_reader.cache_items[cache_items_key], new_item)
            i = i + 1
        end
    end

    function download(url)
        rss_reader.cache.items = {}
        local body, c, h = https_req(url)

        if 200 == c then
            return body
        end
    end

    function merge_items_into_cache()
        rss_reader.cache.items = {}
        for _, items in pairs(rss_reader.cache_items) do
            for _, item in pairs(items) do
                table.insert(rss_reader.cache.items, item)
            end
        end
    end

    function install_download_timer()
        local update_timer = timer({ timeout = args.timeout or 1800 })
        update_timer:connect_signal("timeout", function()
            local items_changes = false
            for i, thread in ipairs(args.rss_threads) do
                local body = download(thread.url)
                local cache_key = "body-" .. thread.url

                if body and rss_reader.cache[cache_key] ~= body then
                    rss_reader.cache[cache_key] = body
                    process_body(thread, body)
                    items_changes = true
                end
            end
            --if items_changes then
                merge_items_into_cache()
                rss_reader.update()
            --end
        end)
        update_timer:emit_signal("timeout")
        update_timer:start()
    end

    function install_next_element_timer()
        local next_element_timer = timer({ timeout = 10 })
        next_element_timer:connect_signal("timeout", function()
            rss_reader.show_next()
        end)
        next_element_timer:emit_signal("timeout")
        next_element_timer:start()
    end

    function install_timers()
        install_download_timer()
        install_next_element_timer()
    end


    install_timers()
    rss_reader.update()

    return rss_reader
end

return factory


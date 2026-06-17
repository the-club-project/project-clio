local battery = {}

local filepath = "/sys/class/power_supply/BAT1/"

local function read_sys(filename)
    local file = io.open(filepath .. filename, "r")

    if not file then return nil end

    local read = file:read("*all")
    file:close()
    return read:gsub("%s+", "")    
end

function battery.info()
    local cap = read_sys("capacity")
    local stat = read_sys("status")
    local ef = read_sys("energy_full")
    local efd = read_sys("energy_full_design")
    local pn = read_sys("power_now")
    local en = read_sys("energy_now")
    if not stat then return nil end
    local stat_char = stat:sub(1,1)

    local percent = math.floor(tonumber(cap))

    return percent, stat_char, ef, efd, pn, en
end

return battery
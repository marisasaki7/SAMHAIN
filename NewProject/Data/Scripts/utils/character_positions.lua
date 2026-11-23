function Display_cg(name, emotion, position)
    local cmd = "cg " .. name .. " sprites/" .. name .. "/SPR_" .. name .. "_" .. emotion .. ".png " .. position .. " -181 0"
    lvCmd(cmd)
end
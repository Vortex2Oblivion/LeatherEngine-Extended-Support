function onEvent(name, position, argument1, argument2)
    if string.lower(name) == "play character animation" then
        local anim = argument2

        if anim == "" then
            anim = "idle"
        end

        playCharAnim(charFromEvent(argument1), anim, true)
    end
end
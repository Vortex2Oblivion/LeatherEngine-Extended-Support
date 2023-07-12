function start( song )
    --                    id    filename  camera
    createCustomShader("example", "example", 120)
    --                       id      camera
    setCameraCustomShader("example", "game")
    setCameraCustomShader("example", "hud")
end
function beatHit( beat )
    if curStep == 25 then -- turning off shaders after 25 beats
        setCameraNoCustomShader("hud")
        setCameraNoCustomShader("game")
    end
end

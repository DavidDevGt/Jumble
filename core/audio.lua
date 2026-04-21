local Audio = {}

Audio.sources = {}
Audio.music = nil
Audio.effects = {}
Audio.masterVolume = 1.0

function Audio.setVolume(volume)
    Audio.masterVolume = math.max(0, math.min(1, volume))
    love.audio.setVolume(Audio.masterVolume)
end

function Audio.getVolume()
    return Audio.masterVolume
end

function Audio.play(source)
    if source then source:play() end
end

function Audio.pause(source)
    if source then source:pause() end
end

function Audio.stop(source)
    if source then source:stop() end
end

function Audio.playAll(sources)
    love.audio.play(sources)
end

function Audio.pauseAll()
    return love.audio.pause()
end

function Audio.stopAll()
    love.audio.stop()
end

function Audio.newSource(filename, type)
    return love.audio.newSource(filename, type or "stream")
end

function Audio.newQueueableSource(samplerate, bitdepth, channels, buffercount)
    samplerate = samplerate or 44100
    bitdepth = bitdepth or 16
    channels = channels or 2
    buffercount = buffercount or 8
    return love.audio.newQueueableSource(samplerate, bitdepth, channels, buffercount)
end

function Audio.getActiveSourceCount()
    return love.audio.getActiveSourceCount()
end

function Audio.setPosition(x, y, z)
    love.audio.setPosition(x or 0, y or 0, z or 0)
end

function Audio.getPosition()
    return love.audio.getPosition()
end

function Audio.setVelocity(x, y, z)
    love.audio.setVelocity(x or 0, y or 0, z or 0)
end

function Audio.getVelocity()
    return love.audio.getVelocity()
end

function Audio.setOrientation(fx, fy, fz, ux, uy, uz)
    love.audio.setOrientation(fx or 0, fy or 0, fz or 0, ux or 0, uy or 0, uz or -1)
end

function Audio.getOrientation()
    return love.audio.getOrientation()
end

function Audio.setDistanceModel(model)
    love.audio.setDistanceModel(model)
end

function Audio.getDistanceModel()
    return love.audio.getDistanceModel()
end

function Audio.setDopplerScale(scale)
    love.audio.setDopplerScale(scale or 1)
end

function Audio.getDopplerScale()
    return love.audio.getDopplerScale()
end

Audio.DistanceModel = {
    NONE = "none",
    INVERSE = "inverse",
    INVERSE_CLAMPED = "inverseclamped",
    LINEAR = "linear",
    LINEAR_CLAMPED = "linearclamped",
    EXPONENT = "exponent",
    EXPONENT_CLAMPED = "exponentclamped"
}

Audio.SourceType = {
    STREAM = "stream",
    STATIC = "static",
    QUEUE = "queue"
}

return Audio
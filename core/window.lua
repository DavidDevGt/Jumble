local Win = {}

function Win.setMode(width, height, flags)
    return love.window.setMode(width, height, flags)
end

function Win.getMode()
    return love.window.getMode()
end

function Win.setFullscreen(fullscreen, fstype)
    return love.window.setFullscreen(fullscreen, fstype)
end

function Win.getFullscreen()
    return love.window.getFullscreen()
end

function Win.setTitle(title)
    love.window.setTitle(title)
end

function Win.getTitle()
    return love.window.getTitle()
end

function Win.setPosition(x, y, displayindex)
    love.window.setPosition(x, y, displayindex)
end

function Win.getPosition()
    return love.window.getPosition()
end

function Win.setVSync(vsync)
    love.window.setVSync(vsync)
end

function Win.getVSync()
    return love.window.getVSync()
end

function Win.minimize()
    love.window.minimize()
end

function Win.maximize()
    love.window.maximize()
end

function Win.restore()
    love.window.restore()
end

function Win.close()
    love.window.close()
end

function Win.isMinimized()
    return love.window.isMinimized()
end

function Win.isMaximized()
    return love.window.isMaximized()
end

function Win.isVisible()
    return love.window.isVisible()
end

function Win.hasFocus()
    return love.window.hasFocus()
end

function Win.hasMouseFocus()
    return love.window.hasMouseFocus()
end

function Win.getDisplayCount()
    return love.window.getDisplayCount()
end

function Win.getDisplayName(displayindex)
    return love.window.getDisplayName(displayindex)
end

function Win.getDesktopDimensions(displayindex)
    return love.window.getDesktopDimensions(displayindex)
end

function Win.getFullscreenModes(displayindex)
    return love.window.getFullscreenModes(displayindex)
end

function Win.getIcon()
    return love.window.getIcon()
end

function Win.setIcon(imagedata)
    return love.window.setIcon(imagedata)
end

function Win.setDisplaySleepEnabled(enable)
    love.window.setDisplaySleepEnabled(enable)
end

function Win.isDisplaySleepEnabled()
    return love.window.isDisplaySleepEnabled()
end

function Win.hasBackgroundMusic()
    return love.system.hasBackgroundMusic()
end

function Win.openURL(url)
    return love.system.openURL(url)
end

function Win.vibrate(seconds)
    love.system.vibrate(seconds)
end

function Win.getSafeArea()
    return love.window.getSafeArea()
end

function Win.getDPIScale()
    return love.window.getDPIScale()
end

function Win.toPixels(value)
    if type(value) == "number" then
        return love.window.toPixels(value)
    else
        return love.window.toPixels(value[1], value[2])
    end
end

function Win.fromPixels(value)
    if type(value) == "number" then
        return love.window.fromPixels(value)
    else
        return love.window.fromPixels(value[1], value[2])
    end
end

function Win.showMessageBox(title, message, buttonlist, messagetype, attachtowindow)
    return love.window.showMessageBox(title, message, buttonlist, messagetype, attachtowindow)
end

Win.FullscreenType = {
    DESKTOP = "desktop",
    EXCLUSIVE = "exclusive"
}

Win.DisplayOrientation = {
    UNKNOWN = "unknown",
    LANDSCAPE = "Landscape",
    LANDSCAPE_FLIPPED = "LandscapeFlipped",
    PORTRAIT = "Portrait",
    PORTRAIT_FLIPPED = "PortraitFlipped"
}

return Win
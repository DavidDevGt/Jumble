local Physics = {}

Physics.world = nil
Physics.meter = 32

function Physics.init(gx, gy, sleep)
    gx = gx or 0
    gy = gy or 0
    sleep = sleep ~= false
    Physics.world = love.physics.newWorld(gx, gy, sleep)
    return Physics.world
end

function Physics.update(dt, velocityiterations, positioniterations)
    velocityiterations = velocityiterations or 8
    positioniterations = positioniterations or 3
    if Physics.world then
        Physics.world:update(dt, velocityiterations, positioniterations)
    end
end

function Physics.newWorld(gx, gy, sleep)
    return love.physics.newWorld(gx, gy, sleep)
end

function Physics.newBody(world, x, y, bodytype)
    return love.physics.newBody(world, x or 0, y or 0, bodytype or "static")
end

function Physics.newCircleShape(radius)
    return love.physics.newCircleShape(radius)
end

function Physics.newRectangleShape(x, y, width, height, angle)
    if x then
        return love.physics.newRectangleShape(x, y, width, height, angle)
    else
        return love.physics.newRectangleShape(width, height)
    end
end

function Physics.newPolygonShape(...)
    return love.physics.newPolygonShape(...)
end

function Physics.newEdgeShape(x1, y1, x2, y2)
    return love.physics.newEdgeShape(x1, y1, x2, y2)
end

function Physics.newChainShape(loop, ...)
    return love.physics.newChainShape(loop, ...)
end

function Physics.newFixture(body, shape, density)
    return love.physics.newFixture(body, shape, density or 1)
end

function Physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, collideConnected)
    return love.physics.newDistanceJoint(body1, body2, x1, y1, x2, y2, collideConnected)
end

function Physics.newRevoluteJoint(body1, body2, x, y, collideConnected, referenceAngle)
    return love.physics.newRevoluteJoint(body1, body2, x, y, collideConnected, referenceAngle)
end

function Physics.newPrismaticJoint(body1, body2, x1, y1, x2, y2, ax, ay, collideConnected, referenceAngle)
    return love.physics.newPrismaticJoint(body1, body2, x1, y1, x2, y2, ax, ay, collideConnected, referenceAngle)
end

function Physics.newMouseJoint(body, x, y)
    return love.physics.newMouseJoint(body, x, y)
end

function Physics.newPulleyJoint(body1, body2, gx1, gy1, gx2, gy2, x1, y1, x2, y2, ratio, collideConnected)
    return love.physics.newPulleyJoint(body1, body2, gx1, gy1, gx2, gy2, x1, y1, x2, y2, ratio, collideConnected)
end

function Physics.newGearJoint(joint1, joint2, ratio, collideConnected)
    return love.physics.newGearJoint(joint1, joint2, ratio, collideConnected)
end

function Physics.newWeldJoint(body1, body2, x, y, collideConnected)
    return love.physics.newWeldJoint(body1, body2, x, y, collideConnected)
end

function Physics.newFrictionJoint(body1, body2, x, y, collideConnected)
    return love.physics.newFrictionJoint(body1, body2, x, y, collideConnected)
end

function Physics.newRopeJoint(body1, body2, x1, y1, x2, y2, maxLength, collideConnected)
    return love.physics.newRopeJoint(body1, body2, x1, y1, x2, y2, maxLength, collideConnected)
end

function Physics.setMeter(scale)
    Physics.meter = scale or 32
    love.physics.setMeter(Physics.meter)
end

function Physics.getMeter()
    return love.physics.getMeter()
end

function Physics.getDistance(fixture1, fixture2)
    return love.physics.getDistance(fixture1, fixture2)
end

Physics.BodyType = {
    STATIC = "static",
    DYNAMIC = "dynamic",
    KINEMATIC = "kinematic"
}

Physics.JointType = {
    DISTANCE = "distance",
    REVOLUTE = "revolute",
    PRISMATIC = "prismatic",
    MOUSE = "mouse",
    PULLEY = "pulley",
    GEAR = "gear",
    WELD = "weld",
    FRICTION = "friction",
    ROPE = "rope"
}

return Physics
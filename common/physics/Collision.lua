-- common/physics/Collision.lua
-- Detección de colisiones AABB (Axis-Aligned Bounding Box)

local Collision = {}

-- Estructura de caja: {x, y, width, height}
function Collision:checkAABB(box1, box2)
    return box1.x < box2.x + box2.width and
           box1.x + box1.width > box2.x and
           box1.y < box2.y + box2.height and
           box1.y + box1.height > box2.y
end

-- Colisión entre punto y caja
function Collision:pointInBox(point, box)
    return point.x >= box.x and
           point.x <= box.x + box.width and
           point.y >= box.y and
           point.y <= box.y + box.height
end

-- Colisión entre círculo y caja
function Collision:circleBoxCollision(circle, box)
    local closestX = math.max(box.x, math.min(circle.x, box.x + box.width))
    local closestY = math.max(box.y, math.min(circle.y, box.y + box.height))
    
    local distanceX = circle.x - closestX
    local distanceY = circle.y - closestY
    
    return (distanceX * distanceX + distanceY * distanceY) < (circle.radius * circle.radius)
end

-- Colisión entre dos círculos
function Collision:circleCircleCollision(circle1, circle2)
    local dx = circle1.x - circle2.x
    local dy = circle1.y - circle2.y
    local distance = math.sqrt(dx * dx + dy * dy)
    
    return distance < (circle1.radius + circle2.radius)
end

return Collision

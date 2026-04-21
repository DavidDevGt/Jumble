-- tests/test_vector2.lua
-- Unit tests for Vector2 math library

local Vector2 = require("common.utils.Vector2")

describe("Vector2", function()
    describe("new", function()
        it("should create vector with x, y", function()
            local v = Vector2:new(3, 4)
            assert.equal(v.x, 3)
            assert.equal(v.y, 4)
        end)
        
        it("should create zero vector by default", function()
            local v = Vector2:new()
            assert.equal(v.x, 0)
            assert.equal(v.y, 0)
        end)
    end)
    
    describe("magnitude", function()
        it("should calculate 3-4-5 right triangle", function()
            local v = Vector2:new(3, 4)
            assert.equal(v:magnitude(), 5)
        end)
        
        it("should return 0 for zero vector", function()
            local v = Vector2:new(0, 0)
            assert.equal(v:magnitude(), 0)
        end)
    end)
    
    describe("normalize", function()
        it("should normalize 3-4-5 vector to length 1", function()
            local v = Vector2:new(3, 4)
            local n = v:normalize()
            
            local expectedX = 3 / 5
            local expectedY = 4 / 5
            
            assert.is_true(math.abs(n.x - expectedX) < 0.0001)
            assert.is_true(math.abs(n.y - expectedY) < 0.0001)
        end)
    end)
    
    describe("clone", function()
        it("should create independent copy", function()
            local v1 = Vector2:new(5, 10)
            local v2 = v1:clone()
            
            v2.x = 100
            
            assert.equal(v1.x, 5)  -- Original unchanged
            assert.equal(v2.x, 100)  -- Copy changed
        end)
    end)
    
    describe("distance", function()
        it("should calculate distance between two points", function()
            local v1 = Vector2:new(0, 0)
            local v2 = Vector2:new(3, 4)
            
            assert.equal(v1:distance(v2), 5)
        end)
    end)
end)

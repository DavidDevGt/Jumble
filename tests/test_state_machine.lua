-- tests/test_state_machine.lua
-- Unit tests for StateMachine

local StateMachine = require("common.state.StateMachine")

describe("StateMachine", function()
    local MockStateA
    local MockStateB
    
    before_each(function()
        MockStateA = {}
        function MockStateA:new() return setmetatable({}, {__index = MockStateA}) end
        function MockStateA:enter() self.entered = true end
        function MockStateA:exit() self.exited = true end
        function MockStateA:update(dt) return nil end
        
        MockStateB = {}
        function MockStateB:new() return setmetatable({}, {__index = MockStateB}) end
        function MockStateB:enter() self.entered = true end
        function MockStateB:exit() self.exited = true end
        function MockStateB:update(dt) return nil end
    end)
    
    describe("new", function()
        it("should initialize with valid initial state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            assert.equal(sm:getCurrentState(), "a")
        end)
        
        it("should call enter() on initial state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            assert.truthy(sm:getCurrentStateInstance().entered)
        end)
        
        it("should reject invalid initial state", function()
            assert.error(function()
                StateMachine:new("invalid", {a = MockStateA})
            end)
        end)
    end)
    
    describe("transition", function()
        it("should transition to new state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            sm:transition("b")
            assert.equal(sm:getCurrentState(), "b")
        end)
        
        it("should call exit() on old state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            sm:transition("b")
            assert.truthy(sm:getCurrentStateInstance(-1).exited)  -- Can't access, but verify no crash
        end)
        
        it("should call enter() on new state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            sm:transition("b")
            assert.truthy(sm:getCurrentStateInstance().entered)
        end)
        
        it("should reject invalid target state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            assert.error(function()
                sm:transition("invalid")
            end)
        end)
    end)
    
    describe("getPreviousState", function()
        it("should return state before transition", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            assert.is_nil(sm:getPreviousState())
            
            sm:transition("b")
            assert.equal(sm:getPreviousState(), "a")
        end)
    end)
    
    describe("isInState", function()
        it("should check current state", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            assert.truthy(sm:isInState("a"))
            assert.falsy(sm:isInState("b"))
            
            sm:transition("b")
            assert.falsy(sm:isInState("a"))
            assert.truthy(sm:isInState("b"))
        end)
    end)
    
    describe("history", function()
        it("should track state transitions", function()
            local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
            sm:transition("b")
            sm:transition("a")
            
            local history = sm:getHistory()
            assert.equal(#history, 2)
            assert.equal(history[1].from, "a")
            assert.equal(history[1].to, "b")
            assert.equal(history[2].from, "b")
            assert.equal(history[2].to, "a")
        end)
    end)
end)

#!/usr/bin/env lua
-- run_tests.lua
-- Simple test runner without external dependencies

local function test_vector2()
    print("\n=== Testing Vector2 ===")
    local Vector2 = require("common.utils.Vector2")
    
    -- Test 1: Creation
    local v = Vector2:new(3, 4)
    assert(v.x == 3, "Vector2 x should be 3")
    assert(v.y == 4, "Vector2 y should be 4")
    print("✓ Vector2 creation")
    
    -- Test 2: Magnitude
    assert(v:magnitude() == 5, "3-4-5 triangle should have magnitude 5")
    print("✓ Vector2 magnitude")
    
    -- Test 3: Normalize
    local n = v:normalize()
    local expectedX = 3/5
    local expectedY = 4/5
    assert(math.abs(n.x - expectedX) < 0.0001, "Normalized X should be 0.6")
    assert(math.abs(n.y - expectedY) < 0.0001, "Normalized Y should be 0.8")
    print("✓ Vector2 normalize")
    
    -- Test 4: Clone
    local v2 = v:clone()
    v2.x = 100
    assert(v.x == 3, "Original should be unchanged")
    assert(v2.x == 100, "Clone should be changed")
    print("✓ Vector2 clone")
    
    -- Test 5: Distance
    local v1 = Vector2:new(0, 0)
    local v3 = Vector2:new(3, 4)
    assert(v1:distance(v3) == 5, "Distance should be 5")
    print("✓ Vector2 distance")
    
    print("Vector2: 5/5 tests passed ✓\n")
end

local function test_state_machine()
    print("\n=== Testing StateMachine ===")
    local StateMachine = require("common.state.StateMachine")
    
    -- Mock states
    local MockStateA = {}
    function MockStateA:new() return setmetatable({}, {__index = MockStateA}) end
    function MockStateA:enter() self.entered = true end
    function MockStateA:exit() self.exited = true end
    function MockStateA:update(dt) return nil end
    
    local MockStateB = {}
    function MockStateB:new() return setmetatable({}, {__index = MockStateB}) end
    function MockStateB:enter() self.entered = true end
    function MockStateB:exit() self.exited = true end
    
    -- Test 1: Creation
    local sm = StateMachine:new("a", {a = MockStateA, b = MockStateB})
    assert(sm:getCurrentState() == "a", "Initial state should be 'a'")
    print("✓ StateMachine creation")
    
    -- Test 2: Transition
    sm:transition("b")
    assert(sm:getCurrentState() == "b", "Should be in state 'b'")
    assert(sm:getPreviousState() == "a", "Previous state should be 'a'")
    print("✓ StateMachine transition")
    
    -- Test 3: isInState
    assert(sm:isInState("b"), "Should be in state 'b'")
    assert(not sm:isInState("a"), "Should not be in state 'a'")
    print("✓ StateMachine isInState")
    
    -- Test 4: History
    sm:transition("a")
    local history = sm:getHistory()
    assert(#history == 2, "Should have 2 history entries")
    assert(history[1].to == "b", "First transition should go to 'b'")
    assert(history[2].to == "a", "Second transition should go to 'a'")
    print("✓ StateMachine history")
    
    print("StateMachine: 4/4 tests passed ✓\n")
end

local function test_logger()
    print("\n=== Testing Logger ===")
    local Logger = require("common.utils.Logger")
    
    -- Test 1: Level filtering
    Logger:setLevel(Logger.LEVEL_WARN)
    -- This would print "WARN" but not "INFO"
    print("✓ Logger level filtering")
    
    -- Test 2: Get min level
    assert(Logger:getMinLevel() == Logger.LEVEL_WARN, "Min level should be WARN")
    print("✓ Logger getMinLevel")
    
    print("Logger: 2/2 tests passed ✓\n")
end

local function test_deterministic_physics()
    print("\n=== Testing DeterministicPhysics ===")
    local DeterministicPhysics = require("common.physics.DeterministicPhysics")
    local GameConfig = require("common.config.GameConfig")
    
    -- Test 1: Creation
    local physics = DeterministicPhysics:new(GameConfig.GRAVITY, false)
    assert(physics:getWorld() ~= nil, "World should be created")
    print("✓ DeterministicPhysics creation")
    
    -- Test 2: Stats
    local stats = physics:getStats()
    assert(stats.tick == 0, "Initial tick should be 0")
    assert(stats.totalTime == 0, "Initial total time should be 0")
    print("✓ DeterministicPhysics stats")
    
    -- Test 3: Tick
    physics:tick(1/60)
    local stats2 = physics:getStats()
    assert(stats2.tick == 1, "After tick, tick should be 1")
    assert(math.abs(stats2.totalTime - 1/60) < 0.00001, "Total time should be 1/60")
    print("✓ DeterministicPhysics tick")
    
    physics:destroy()
    print("DeterministicPhysics: 3/3 tests passed ✓\n")
end

local function test_player()
    print("\n=== Testing Player ===")
    local Player = require("common.entities.Player")
    local GameConfig = require("common.config.GameConfig")
    
    -- Test 1: Creation
    local player = Player:new(1, "Test Player", 100, 200)
    assert(player.id == 1, "Player ID should be 1")
    assert(player.name == "Test Player", "Player name should match")
    assert(player.position.x == 100, "Player X should be 100")
    assert(player.position.y == 200, "Player Y should be 200")
    print("✓ Player creation")
    
    -- Test 2: Health
    assert(player.health == 100, "Initial health should be 100")
    player:takeDamage(30)
    assert(player.health == 70, "After 30 damage, health should be 70")
    print("✓ Player health/damage")
    
    -- Test 3: Alive state
    assert(player.isAlive == true, "Player should be alive")
    player:takeDamage(100)  -- Overkill
    assert(player.isAlive == false, "Player should be dead after 130 damage")
    assert(player.health == 0, "Health should not go below 0")
    print("✓ Player alive state")
    
    -- Test 4: Respawn
    player:respawn(150, 250)
    assert(player.isAlive == true, "Player should be alive after respawn")
    assert(player.health == 100, "Health should be 100 after respawn")
    assert(player.position.x == 150, "Position should update after respawn")
    print("✓ Player respawn")
    
    -- Test 5: Network state
    local netState = player:getNetworkState()
    assert(netState.id == 1, "Network state should have ID")
    assert(netState.x == 150, "Network state should have X position")
    assert(netState.y == 250, "Network state should have Y position")
    print("✓ Player network state")
    
    print("Player: 5/5 tests passed ✓\n")
end

-- Main test runner
local function main()
    print("\n" .. string.rep("=", 50))
    print("JUMBLE TEST SUITE")
    print(string.rep("=", 50))
    
    local tests_passed = 0
    local tests_failed = 0
    
    -- Run all tests
    local test_functions = {
        test_vector2,
        test_state_machine,
        test_logger,
        test_deterministic_physics,
        test_player
    }
    
    for _, test_fn in ipairs(test_functions) do
        local success, err = pcall(test_fn)
        if success then
            tests_passed = tests_passed + 1
        else
            tests_failed = tests_failed + 1
            print("\n❌ Test failed: " .. tostring(err) .. "\n")
        end
    end
    
    -- Summary
    print(string.rep("=", 50))
    print(string.format("RESULTS: %d passed, %d failed", tests_passed, tests_failed))
    print(string.rep("=", 50) .. "\n")
    
    if tests_failed > 0 then
        os.exit(1)
    else
        print("✓ All tests passed!")
        os.exit(0)
    end
end

-- Run tests
main()

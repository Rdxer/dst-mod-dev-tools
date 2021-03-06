require "busted.runner"()

describe("WorldDevTools", function()
    -- setup
    local match

    -- before_each initialization
    local devtools, inst
    local WorldDevTools, worlddevtools

    setup(function()
        -- match
        match = require "luassert.match"

        -- debug
        DebugSpyTerm()
        DebugSpyInit(spy)
    end)

    teardown(function()
        -- debug
        DebugSpyTerm()

        -- globals
        _G.ConsoleRemote = nil
        _G.GetDebugEntity = nil
        _G.SetDebugEntity = nil
        _G.StartThread = nil
        _G.TheInput = nil
        _G.TheSim = nil
    end)

    before_each(function()
        -- globals
        _G.ConsoleRemote = spy.new(Empty)
        _G.GetDebugEntity = spy.new(ReturnValueFn("GetDebugEntity"))
        _G.SetDebugEntity = spy.new(Empty)
        _G.StartThread = spy.new(Empty)
        _G.TheInput = spy.new(Empty)
        _G.TheSim = MockTheSim()

        -- initialization
        devtools = MockDevTools()
        inst = MockWorldInst()

        WorldDevTools = require "devtools/devtools/worlddevtools"
        worlddevtools = WorldDevTools(inst, devtools)

        WorldDevTools.StartPrecipitationThread = spy.new(Empty)
        WorldDevTools.GuessMapKeyPositions = spy.new(Empty)
        WorldDevTools.GuessNrOfWalrusCamps = spy.new(Empty)
        WorldDevTools.LoadSaveData = spy.new(Empty)
        WorldDevTools.StartPrecipitationThread = spy.new(Empty)

        DebugSpyClear()
    end)

    insulate("initialization", function()
        before_each(function()
            -- general
            devtools = MockDevTools()

            -- initialization
            WorldDevTools = require "devtools/devtools/worlddevtools"
        end)

        local function AssertDefaults(self)
            assert.is_equal(devtools, self.devtools)
            assert.is_equal("WorldDevTools", self.name)

            -- general
            assert.is_equal(inst, self.inst)
            assert.is_equal(inst.ismastersim, self.inst.ismastersim)

            -- map
            assert.is_false(self.is_map_clearing)
            assert.is_true(self.is_map_fog_of_war)

            -- precipitation
            assert.is_nil(self.precipitation_ends)
            assert.is_nil(self.precipitation_starts)
            assert.is_nil(self.precipitation_thread)

            -- upvalues
            assert.is_nil(self.weathermoisturefloor)
            assert.is_nil(self.weathermoisturerate)
            assert.is_nil(self.weatherpeakprecipitationrate)
            assert.is_nil(self.weatherwetrate)

            -- spies
            assert.spy(self.StartPrecipitationThread).was_called(1)
            assert.spy(self.StartPrecipitationThread).was_called_with(match.is_ref(self))

            -- DevTools
            assert.is_equal(self.inst.ismastersim, self.devtools.ismastersim)
        end

        describe("using the constructor", function()
            before_each(function()
                worlddevtools = WorldDevTools(inst, devtools)
            end)

            it("should have the default fields", function()
                AssertDefaults(worlddevtools)
            end)
        end)

        it("should add DevTools methods", function()
            local methods = {
                SelectWorld = "Select",
                SelectWorldNet = "SelectNet",

                -- general
                "IsMasterSim",
                "GetWorld",
                "GetWorldNet",
                "IsCave",
                "GetMeta",
                "GetSeed",
                "GetTimeUntilPhase",
                "GetPhase",
                "GetNextPhase",

                -- selection
                "GetSelectedEntity",
                "SelectEntityUnderMouse",

                -- state
                "GetState",
                "GetStateCavePhase",
                "GetStateIsSnowing",
                "GetStateMoisture",
                "GetStateMoistureCeil",
                "GetStatePhase",
                "GetStatePrecipitationRate",
                "GetStateRemainingDaysInSeason",
                "GetStateSeason",
                "GetStateSnowLevel",
                "GetStateTemperature",
                "GetStateWetness",

                -- map
                "IsMapClearing",
                "IsMapFogOfWar",
                "ToggleMapClearing",
                "ToggleMapFogOfWar",

                -- weather
                "GetWeatherComponent",
                "GetMoistureFloor",
                "GetMoistureRate",
                "GetPeakPrecipitationRate",
                "GetWetnessRate",
                --"WeatherOnUpdate",
                "GetPrecipitationStarts",
                "GetPrecipitationEnds",
                "IsPrecipitation",
                "StartPrecipitationThread",
                "ClearPrecipitationThread",
            }

            AssertAddedMethodsBefore(methods, devtools)
            worlddevtools = WorldDevTools(inst, devtools)
            AssertAddedMethodsAfter(methods, worlddevtools, devtools)
        end)
    end)

    describe("general", function()
        it("should have the getter GetWorld", function()
            AssertGetter(worlddevtools, "inst", "GetWorld")
        end)

        describe("GetWeatherComponent", function()
            local IsCave

            describe("when in the cave", function()
                before_each(function()
                    IsCave = spy.new(ReturnValueFn(true))
                    worlddevtools.inst.net.components.caveweather = "caveweather"
                    worlddevtools.IsCave = IsCave
                end)

                it("should call the WorldDevTools:IsCave()", function()
                    assert.spy(IsCave).was_not_called()
                    worlddevtools:IsCave()
                    assert.spy(IsCave).was_called(1)
                    assert.spy(IsCave).was_called_with(match.is_ref(worlddevtools))
                end)

                it("should return CaveWeather component", function()
                    assert.is_equal("caveweather", worlddevtools:GetWeatherComponent())
                end)

                describe("and the CaveWeather component is missing", function()
                    before_each(function()
                        worlddevtools.inst.net.components.caveweather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(worlddevtools:GetWeatherComponent())
                    end)
                end)
            end)

            describe("when not in the cave", function()
                before_each(function()
                    IsCave = spy.new(ReturnValueFn(false))
                    worlddevtools.inst.net.components.weather = "weather"
                    worlddevtools.IsCave = IsCave
                end)

                it("should call the WorldDevTools:IsCave()", function()
                    assert.spy(IsCave).was_not_called()
                    worlddevtools:IsCave()
                    assert.spy(IsCave).was_called(1)
                    assert.spy(IsCave).was_called_with(match.is_ref(worlddevtools))
                end)

                it("should return Weather component", function()
                    assert.is_equal("weather", worlddevtools:GetWeatherComponent())
                end)

                describe("and the Weather component is missing", function()
                    before_each(function()
                        worlddevtools.inst.net.components.weather = nil
                    end)

                    it("should return nil", function()
                        assert.is_nil(worlddevtools:GetWeatherComponent())
                    end)
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(worlddevtools:GetWeatherComponent())
                    end, worlddevtools, "inst", "net", "components")
                end)
            end)
        end)

        describe("GetTimeUntilPhase", function()
            local clock, GetTimeUntilPhase

            before_each(function()
                clock = worlddevtools.inst.net.components.clock
                GetTimeUntilPhase = clock.GetTimeUntilPhase
            end)

            it("should call the Clock:GetTimeUntilPhase()", function()
                assert.spy(GetTimeUntilPhase).was_not_called()
                worlddevtools:GetTimeUntilPhase("day")
                assert.spy(GetTimeUntilPhase).was_called(1)
                assert.spy(GetTimeUntilPhase).was_called_with(match.is_ref(clock), "day")
            end)

            it("should return Clock:GetTimeUntilPhase() value", function()
                assert.is_equal(10, worlddevtools:GetTimeUntilPhase("day"))
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(worlddevtools:GetTimeUntilPhase())
                    end, worlddevtools, "inst", "net", "components", "clock")
                end)
            end)
        end)

        describe("GetWorldNet", function()
            it("should return TheWorld.net", function()
                assert.is_equal(worlddevtools.inst.net, worlddevtools:GetWorldNet())
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(worlddevtools:GetWorldNet())
                    end, worlddevtools, "inst", "net")
                end)
            end)
        end)

        describe("GetMeta", function()
            describe("when no name is passed", function()
                it("should return TheWorld.meta", function()
                    assert.is_equal(worlddevtools.inst.meta, worlddevtools:GetMeta())
                end)
            end)

            describe("when the name is passed", function()
                it("should return TheWorld.meta field value", function()
                    assert.is_equal(
                        worlddevtools.inst.meta.saveversion,
                        worlddevtools:GetMeta("saveversion")
                    )
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(worlddevtools:GetMeta("saveversion"))
                    end, worlddevtools, "inst", "meta", "saveversion")
                end)
            end)
        end)

        describe("GetSeed", function()
            it("should return TheWorld.meta.seed", function()
                assert.is_equal(worlddevtools.inst.meta.seed, worlddevtools:GetSeed())
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(worlddevtools:GetSeed())
                    end, worlddevtools, "inst", "meta", "seed")
                end)
            end)
        end)

        describe("IsCave", function()
            describe("when in the cave", function()
                local HasTag

                before_each(function()
                    HasTag = spy.new(function(_, tag)
                        return tag == "cave"
                    end)

                    worlddevtools.inst.HasTag = HasTag
                end)

                it("should call the TheWorld:HasTag()", function()
                    assert.spy(HasTag).was_not_called()
                    worlddevtools:IsCave()
                    assert.spy(HasTag).was_called(1)
                    assert.spy(HasTag).was_called_with(match.is_ref(worlddevtools.inst), "cave")
                end)

                it("should return true", function()
                    assert.is_true(worlddevtools:IsCave())
                end)
            end)

            describe("when not in the cave", function()
                local HasTag

                before_each(function()
                    HasTag = spy.new(ReturnValueFn(false))
                    worlddevtools.inst.HasTag = HasTag
                end)

                it("should call the TheWorld:HasTag()", function()
                    assert.spy(HasTag).was_not_called()
                    worlddevtools:IsCave()
                    assert.spy(HasTag).was_called(1)
                    assert.spy(HasTag).was_called_with(match.is_ref(worlddevtools.inst), "cave")
                end)

                it("should return false", function()
                    assert.is_false(worlddevtools:IsCave())
                end)
            end)

            describe("when some chain fields are missing", function()
                it("should return nil", function()
                    AssertChainNil(function()
                        assert.is_nil(worlddevtools:IsCave())
                    end, worlddevtools, "inst")
                end)
            end)
        end)

        describe("GetPhase", function()
            local GetStatePhase, GetStateCavePhase

            before_each(function()
                GetStatePhase = spy.on(worlddevtools, "GetStatePhase")
                GetStateCavePhase = spy.on(worlddevtools, "GetStateCavePhase")
                worlddevtools.IsCave = ReturnValueFn(true)
            end)

            describe("when in the cave", function()
                before_each(function()
                    worlddevtools.IsCave = ReturnValueFn(true)
                end)

                it("should call the GetStateCavePhase()", function()
                    assert.spy(GetStateCavePhase).was_not_called()
                    worlddevtools:GetPhase()
                    assert.spy(GetStateCavePhase).was_called(1)
                    assert.spy(GetStateCavePhase).was_called_with(match.is_ref(worlddevtools))
                end)

                it("shouldn't call the GetStatePhase()", function()
                    assert.spy(GetStatePhase).was_not_called()
                    worlddevtools:GetPhase()
                    assert.spy(GetStatePhase).was_not_called()
                end)
            end)

            describe("when in the cave", function()
                before_each(function()
                    worlddevtools.IsCave = ReturnValueFn(false)
                end)

                it("should call the GetStatePhase()", function()
                    assert.spy(GetStatePhase).was_not_called()
                    worlddevtools:GetPhase()
                    assert.spy(GetStatePhase).was_called(1)
                    assert.spy(GetStatePhase).was_called_with(match.is_ref(worlddevtools))
                end)

                it("shouldn't call the GetStateCavePhase()", function()
                    assert.spy(GetStateCavePhase).was_not_called()
                    worlddevtools:GetPhase()
                    assert.spy(GetStateCavePhase).was_not_called()
                end)
            end)
        end)

        describe("GetNextPhase", function()
            describe("when the phase is passed", function()
                it("should return the next phase", function()
                    assert.is_equal("dusk", worlddevtools:GetNextPhase("day"))
                    assert.is_equal("night", worlddevtools:GetNextPhase("dusk"))
                    assert.is_equal("day", worlddevtools:GetNextPhase("night"))
                end)
            end)

            describe("when the phase is not passed", function()
                it("should return nil", function()
                    assert.is_nil(worlddevtools:GetNextPhase())
                end)
            end)
        end)
    end)

    describe("selection", function()
        describe("GetSelectedEntity", function()
            it("should call the GetDebugEntity()", function()
                assert.spy(GetDebugEntity).was_not_called()
                worlddevtools:GetSelectedEntity()
                assert.spy(GetDebugEntity).was_called(1)
                assert.spy(GetDebugEntity).was_called_with()
            end)

            it("should return GetDebugEntity() value", function()
                assert.is_equal("GetDebugEntity", worlddevtools:GetSelectedEntity())
            end)
        end)

        describe("Select", function()
            it("should call the SetDebugEntity()", function()
                assert.spy(SetDebugEntity).was_not_called()
                worlddevtools:Select()
                assert.spy(SetDebugEntity).was_called(1)
                assert.spy(SetDebugEntity).was_called_with(match.is_ref(worlddevtools.inst))
            end)

            it("should debug string", function()
                worlddevtools:Select()
                DebugSpyAssertWasCalled("DebugString", 1, {
                    "Selected TheWorld"
                })
            end)

            it("should return true", function()
                assert.is_true(worlddevtools:Select())
            end)
        end)

        describe("SelectNet", function()
            it("should call the SetDebugEntity()", function()
                assert.spy(SetDebugEntity).was_not_called()
                worlddevtools:SelectNet()
                assert.spy(SetDebugEntity).was_called(1)
                assert.spy(SetDebugEntity).was_called_with(match.is_ref(worlddevtools.inst.net))
            end)

            it("should debug string", function()
                worlddevtools:SelectNet()
                DebugSpyAssertWasCalled("DebugString", 1, {
                    "Selected TheWorld.net"
                })
            end)

            it("should return true", function()
                assert.is_true(worlddevtools:SelectNet())
            end)
        end)

        describe("SelectEntityUnderMouse", function()
            local GetWorldEntityUnderMouse

            before_each(function()
                GetWorldEntityUnderMouse = spy.new(
                    ReturnValueFn({ GetDisplayName = ReturnValueFn("Test") })
                )

                _G.TheInput.GetWorldEntityUnderMouse = GetWorldEntityUnderMouse
            end)

            it("should call the TheInput:GetWorldEntityUnderMouse()", function()
                assert.spy(GetWorldEntityUnderMouse).was_not_called()
                worlddevtools:SelectEntityUnderMouse()
                assert.spy(GetWorldEntityUnderMouse).was_called(1)
                assert.spy(GetWorldEntityUnderMouse).was_called_with(match.is_ref(TheInput))
            end)

            describe("when there is an entity under mouse", function()
                it("should debug string", function()
                    worlddevtools:SelectEntityUnderMouse()
                    DebugSpyAssertWasCalled("DebugString", 1, {
                        "Selected",
                        "Test"
                    })
                end)

                it("should return true", function()
                    assert.is_true(worlddevtools:SelectEntityUnderMouse())
                end)
            end)

            describe("when there is no entity under mouse", function()
                before_each(function()
                    GetWorldEntityUnderMouse = ReturnValueFn(nil)
                    _G.TheInput.GetWorldEntityUnderMouse = GetWorldEntityUnderMouse
                end)

                it("should return false", function()
                    assert.is_false(worlddevtools:SelectEntityUnderMouse())
                end)
            end)
        end)
    end)

    describe("state", function()
        describe("should have the getter", function()
            it("GetState", function()
                assert.is_equal(worlddevtools.inst.state, worlddevtools:GetState())
                assert.is_equal(worlddevtools.inst.state.season, worlddevtools:GetState("season"))

                worlddevtools.inst.state.season = nil
                assert.is_nil(worlddevtools:GetState("season"))
                worlddevtools.inst.state = nil
                assert.is_nil(worlddevtools:GetState("season"))
                worlddevtools.inst = nil
                assert.is_nil(worlddevtools:GetState("season"))
            end)

            local getters = {
                cavephase = "GetStateCavePhase",
                issnowing = "GetStateIsSnowing",
                moisture = "GetStateMoisture",
                moistureceil = "GetStateMoistureCeil",
                phase = "GetStatePhase",
                precipitationrate = "GetStatePrecipitationRate",
                remainingdaysinseason = "GetStateRemainingDaysInSeason",
                season = "GetStateSeason",
                snowlevel = "GetStateSnowLevel",
                temperature = "GetStateTemperature",
                wetness = "GetStateWetness",
            }

            for field, getter in pairs(getters) do
                it(getter, function()
                    local fn = worlddevtools[getter]
                    assert.is_equal(worlddevtools.inst.state[field], fn(worlddevtools))

                    worlddevtools.inst.state[field] = nil
                    assert.is_nil(fn(worlddevtools))
                    worlddevtools.inst.state = nil
                    assert.is_nil(fn(worlddevtools))
                    worlddevtools.inst = nil
                    assert.is_nil(fn(worlddevtools))
                end)
            end
        end)
    end)

    describe("map", function()
        describe("should have the getter", function()
            local getters = {
                is_map_clearing = "IsMapClearing",
                is_map_fog_of_war = "IsMapFogOfWar",
            }

            for field, getter in pairs(getters) do
                it(getter, function()
                    AssertGetter(worlddevtools, field, getter)
                end)
            end
        end)
    end)

    describe("weather", function()
        describe("should have the", function()
            describe("getter", function()
                local getters = {
                    moisture_floor = "GetMoistureFloor",
                    moisture_rate = "GetMoistureRate",
                    peak_precipitation_rate = "GetPeakPrecipitationRate",
                    wetness_rate = "GetWetnessRate",
                    precipitation_starts = "GetPrecipitationStarts",
                    precipitation_ends = "GetPrecipitationEnds",
                }

                for field, getter in pairs(getters) do
                    it(getter, function()
                        AssertGetter(worlddevtools, field, getter)
                    end)
                end
            end)
        end)
    end)
end)

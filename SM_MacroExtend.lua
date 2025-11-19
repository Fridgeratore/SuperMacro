-- SuperMacroExtend handlers

-- string: saved current extend script page to show.
local currentPageId


-- Change current page to new Id
local function SetCurrentPage(pageId)
    currentPageId = pageId
    local extendText
    if currentPageId then
        extendText=SM_EXTEND[currentPageId]
    end
    if extendText then
        SuperMacroFrameExtendText:SetText(extendText)
    else
        -- Create new or invalid id. Show empty text
        SuperMacroFrameExtendText:SetText("")
    end
end

-- Save current extend script text to SM_EXTEND and update UI
local function SaveCurrentPage()
    if not currentPageId then
        return
    end

    local text=SuperMacroFrameExtendText:GetText()
    if text and text~="" then
        SM_EXTEND[currentPageId]=text
    else
        -- auto delete empty page
        SM_EXTEND[currentPageId]=nil
    end

    SuperMacroFrameExtendText:ClearFocus()
    SuperMacroSaveExtendButton:SetTextColor(0.5, 0.5, 0.5)
end

-- Run all current scripts
local function RunAllScripts()
    for m,e in pairs(SM_EXTEND) do
        if ( e ) then
            RunScript(e)
        end
    end
end




-- External functions
-- Initialize extend macro
function SuperMacroInitExtend()
    RunAllScripts()
end

-- Save current UI text changes and run scripts
function SuperMacroRunAllExtend()
    SaveCurrentPage()
	RunAllScripts()
end

function SuperMacroSelectExtend(pageId)
    SaveCurrentPage()
    SetCurrentPage(pageId)
end

function SuperMacroCopyExtend(fromId, toId)
    assert(fromId ~= toId)
    SaveCurrentPage()

    local text = SM_EXTEND[fromId]
    SM_EXTEND[toId] = text
end

function SuperMacroDeleteExtend(pageId)
    SaveCurrentPage()
    SM_EXTEND[pageId]=nil
    if pageId == currentPageId then
        -- Update script UI
        SetCurrentPage(pageId)
    end
end

-- Save button action
function SuperMacroSaveExtendButton_OnClick()
    SuperMacroRunAllExtend()
end

-- Delete button action
function SuperMacroDeleteExtendButton_OnClick()
    if currentPageId then
        SuperMacroDeleteExtend(currentPageId)
    end
    SuperMacroRunAllExtend()
end

-- UI change text action
function SuperMacroFrameExtendText_OnTextChanged()
    SuperMacroFrameExtendCharLimitText:SetText(format(TEXT(SUPERMACROFRAME_EXTEND_CHAR_LIMIT), strlen(SuperMacroFrameExtendText:GetText())))
    SuperMacroHandleEditBox(SuperMacroFrameExtendText)
    SuperMacroSaveExtendButton:SetTextColor(1, 0.82, 0)
end

function SuperMacroSetDefaultTooltipColor(frame)
    frame:SetBackdropBorderColor(TOOLTIP_DEFAULT_COLOR.r, TOOLTIP_DEFAULT_COLOR.g, TOOLTIP_DEFAULT_COLOR.b);
    frame:SetBackdropColor(TOOLTIP_DEFAULT_BACKGROUND_COLOR.r, TOOLTIP_DEFAULT_BACKGROUND_COLOR.g, TOOLTIP_DEFAULT_BACKGROUND_COLOR.b);
end



-- Initialize assigned curse
if not CurrentCurse then CurrentCurse = "Curse of Shadow" end
if not LastShadowTranceCast then LastShadowTranceCast = 0 end

-- Buff/Debuff helpers
function HasBuff(buff)
  for i = 1, 40 do
    local name = UnitBuff("player", i)
    if not name then break end
    if name and string.find(name, buff) then
      return true
    end
  end
  return false
end

function TargetHasDebuff(spellName)
  if not UnitExists("target") then return false end
  local _, guid = UnitExists("target")
  local data = Cursive.curses:GetCurseData(spellName, guid)
  if not data then return false end
  if Cursive.curses:TimeRemaining(data) <= 0 then return false end
  return true
end




-- Main Warlock rotation
function WarlockRotation()
  if not UnitExists("target") then return end
  local now = GetTime()

  -- 2. Apply assigned curse first if missing
  if not TargetHasDebuff(CurrentCurse) then
    ChannelStopCastingNextTick()
    CastSpellByName(CurrentCurse)
    return
  end

  -- 3. Apply other DoTs if missing
  for _, curse in ipairs({"Corruption", "Curse of Agony", "Siphon Life"}) do
    if not TargetHasDebuff(curse) then
      ChannelStopCastingNextTick()
      CastSpellByName(curse)
      return
    end
  end

  -- 4. Filler
  CastSpellByName("Drain Soul")
end

function WarlockRotationChess()
  if not UnitExists("target") then return end
  local now = GetTime()

  -- 1. Shadow Trance proc → instant Shadow Bolt
  --if HasBuff("Spell_Shadow_Twilight") and (now - LastShadowTranceCast > 1) then
    --ChannelStopCastingNextTick()
    --CastSpellByName("Shadow Bolt")
    --LastShadowTranceCast = now
    --return
  --end

  -- 2. Apply assigned curse first if missing
  if not TargetHasDebuff(CurrentCurse) then
    ChannelStopCastingNextTick()
    CastSpellByName(CurrentCurse)
    return
  end

  -- 3. Apply other DoTs if missing
  for _, curse in ipairs({"Corruption", "Curse of Agony"}) do
    if not TargetHasDebuff(curse) then
      ChannelStopCastingNextTick()
      CastSpellByName(curse)
      return
    end
  end

  -- 4. Filler
  CastSpellByName("Drain Soul")
end



-- Toggle function to cycle through your assigned curses
function ToggleCurseRole()
  if CurrentCurse == "Curse of Shadow" then
    CurrentCurse = "Curse of Recklessness"
    elseif CurrentCurse == "Curse of Recklessness" then
        CurrentCurse = "Curse of the Elements"
    elseif CurrentCurse == "Curse of the Elements" then
        CurrentCurse = "Curse of Weakness"
    elseif CurrentCurse == "Curse of Weakness" then
        CurrentCurse = "Curse of Tongues"
  else
    CurrentCurse = "Curse of Shadow"
  end
  DEFAULT_CHAT_FRAME:AddMessage("Current Assigned Curse: " .. CurrentCurse)
end






-- Hardcoded Dark Harvest slot
local DarkHarvestSlot = 43

function GetRemainingDuration(unit, spells)
    local lowest = 999
    if not UnitExists(unit) then return 0 end
    local _, guid = UnitExists(unit)

    for _, spell in ipairs(spells) do
        local data = Cursive.curses:GetCurseData(spell, guid)
        if data then
            local remaining = Cursive.curses:TimeRemaining(data)
            if remaining and remaining < lowest then
                lowest = remaining
            end
        end
    end

    return lowest == 999 and 0 or lowest
end





function TargetDebuffRemaining(spellName)
  if not UnitExists("target") then return 0 end
  local _, guid = UnitExists("target")
  local data = Cursive.curses:GetCurseData(spellName, guid)
  if not data then return 0 end
  return Cursive.curses:TimeRemaining(data)
end







-- Main Warlock rotation
-- Anti-Drain-Soul safety timer
local lastDotCastTime = 0

function WarlockRotationTest()
    if not UnitExists("target") then return end

    -- 1. Apply assigned curse if missing
    if not TargetHasDebuff(CurrentCurse) then
        ChannelStopCastingNextTick()
        CastSpellByName(CurrentCurse)
        lastDotCastTime = GetTime()
        return
    end

    -- 2. Apply other DoTs if missing
    for _, dot in ipairs({"Corruption", "Curse of Agony", "Siphon Life"}) do
        if not TargetHasDebuff(dot) then
            ChannelStopCastingNextTick()
            CastSpellByName(dot)
            lastDotCastTime = GetTime()
            return
        end
    end

    -- 3. Dark Harvest logic
    local start, duration, enabled = GetSpellCooldown(DarkHarvestSlot, BOOKTYPE_SPELL)
    local remainingCD = (start + duration) - GetTime()
    local dotsRemaining = GetRemainingDuration("target", {"Corruption","Curse of Agony","Siphon Life"})

    -- Anti-Drain Soul safety window:
    -- Prevent DS from being cast immediately after casting a DoT
    if GetTime() - lastDotCastTime < 0.7 then
        return
    end

    -- 4. Cast Dark Harvest or Drain Soul
    if enabled == 1 and remainingCD <= 0 and dotsRemaining > 5 then
        ChannelStopCastingNextTick()
        QueueSpellByName("Dark Harvest")
    else
        CastSpellByName("Drain Soul")
    end
end
















function rdmg()
    if not st_timer or not UnitAttackSpeed("player") then return end

    

    local total = UnitAttackSpeed("player")
    local remaining = st_timer
    local elapsed = total - remaining

    -- set fixed time windows in seconds
    local earlyWindow = 1.4    -- first X seconds after swing starts
    --local lateWindow  = 0.   -- last X seconds before swing lands

    if not UnitExists("target") or UnitIsDeadOrGhost("target") then
        TargetNearestEnemy()
    end

    -- Start auto attack if not active
    if not IsCurrentAction(1) then
        UseAction(1)
    end

    -- if in the first 1.4 s of the swing, or last 0.19 s (to account for ms), cast Slam
    if elapsed <= earlyWindow then
        CastSpellByName("Slam")
        --print(string.format("Casting Slam | elapsed: %.2fs, remaining: %.2fs", elapsed, remaining))
    end
end




function RogueAttackLogic()
    -- If no target or target is dead, acquire a new one
    if not UnitExists("target") or UnitIsDeadOrGhost("target") then
        TargetNearestEnemy()
    end

    -- Start auto attack if not active
    if not IsCurrentAction(1) then
        UseAction(1)
    end

    -- Cast Envenom if not active, else Slice and Dice if not active
    if not buffed("Envenom") then
        CastSpellByName("Envenom")
    elseif not buffed("Slice and Dice") then
        CastSpellByName("Slice and Dice")
    end

    -- Use Rupture if at 5 combo points
    if GetComboPoints("player", "target") == 5 then
        CastSpellByName("Rupture")
    end

    -- Cast Noxious Assault (Rank 3)
    CastSpellByName("Noxious Assault(Rank 3)")
end

function buffed(name)
    for i=1,16 do
        local buff = UnitBuff("player", i)
        if buff and string.find(buff, name) then
            return true
        end
    end
    return false
end





function MultiDotKite(NOMBRE)

  -- Try Curse of Exhaustion first
  if not Cursive:Multicurse("Curse of Shadow", "HIGHEST_HP", {name=NOMBRE, refreshtime=2, warnings=true, resistsound=true, expiringsound=true}) then
    -- Then try Siphon Life
    if not Cursive:Multicurse("Siphon Life", "HIGHEST_HP", {name=NOMBRE}) then
      -- Then Corruption
      if not Cursive:Multicurse("Corruption", "HIGHEST_HP", {name=NOMBRE}) then
        -- Finally Curse of Agony
        Cursive:Multicurse("Curse of Agony", "HIGHEST_HP", {name=NOMBRE})
      end
    end
  end
end



function HunterSmart()
    if (not UnitExists("target") or UnitIsDead("target")) and enemy then
        TargetByName(enemy, true)
    end

    -- After re-targeting, send pet
    if UnitExists("target") and not UnitIsDead("target") then
        PetAttack()
    end

    local inMelee = CheckInteractDistance("target", 3) -- ~10 yd melee

    if inMelee then
        -- Always activate auto attack for melee
        if not _a then
            for i = 1, 72 do
                if IsAttackAction(i) then
                    _a = i
                    break
                end
            end
        end
        if not IsCurrentAction(_a) then
            UseAction(_a)
        end

        -- Fire melee macro (Raptor Strike + Mongoose Bite)
        UseAction(1)

    else
        -- Activate Auto Shot if not already active
        if not IsAutoRepeatAction(3) then
            UseAction(3)
        end

        -- Try to fire Steady Shot with fallback to CastSpellByName if Quiver is bugged
        if Quiver and Quiver.GetSecondsRemainingReload and Quiver.GetSecondsRemainingShoot then
            local reloading, reloadLeft = Quiver.GetSecondsRemainingReload()
            local _, shootTimeLeft = Quiver.GetSecondsRemainingShoot()
            local bugged = shootTimeLeft and shootTimeLeft < -0.25
            if not reloading or reloadLeft > 0.2 then
                local castFunc = bugged and CastSpellByName or Quiver.CastNoClip
                castFunc("Steady Shot")
            end
        end

    end
end

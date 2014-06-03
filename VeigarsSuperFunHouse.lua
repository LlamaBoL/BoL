local version = "4.0"
--[[
Veigar's Super FunHouse! by llama

]]--

if myHero.charName ~= "Veigar" then return end


local AUTOUPDATE = true
local SCRIPT_NAME = "VeigarsSuperFunHouse"
local UPDATE_HOST = "raw.github.com"
local UPDATE_PATH = "/LlamaBoL/BoL/master/VeigarsSuperFunHouse.lua".."?rand="..math.random(1,10000)
local UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
local VERSION_PATH = "LlamaBoL/BoL/master/Version/"..SCRIPT_NAME..".version"
local SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
local SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"


if FileExist(SOURCELIB_PATH) then
  require("SourceLib")
else
  DOWNLOADING_SOURCELIB = true
  DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() PrintChat("Required libraries downloaded successfully, please reload") end)
end

if AUTOUPDATE then
  SourceUpdater(SCRIPT_NAME, version, UPDATE_HOST,UPDATE_PATH, SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, VERSION_PATH):CheckUpdate()
end

local libDownload = Require("SourceLib")
libDownload:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
libDownload:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
libDownload:Add("comboLib","https://raw.github/LlamaBoL/BoL/master/Common/comboLib.lua")
libDownload:Check()

if libDownload.downloadNeeded == true then return end

function OnLoad()
  player = myHero

  spaceHK = 32 --hk for "spacebar" by default.

  --Options
  comboTimeout = 3000

  eCircleColor = ARGB(255,255,0,255)--0xB820C3 -- purple by default
  wCircleColor = ARGB(255,255,0,0)--0xEA3737 -- orange by default
  qCircleColor = ARGB(255,0,255,0)--0x19A712 --green by default

  drawKillColor1 = ARGB(255,255,0,0) --red
  drawKillColor2 = ARGB(255,0,255,0)--green

  circleRadius = 100 --radius of circle drawn
  circleThickness = 10 --Higher means more vibrant circle. More cpu usage.

  --Skill attributes
  qrange = 650
  wcastspeed = 1.25 -- (s) calculated from tick values
  wrange = 900
  wradius = 230 --maximum radius of W

  eradius = 330 -- event horizon's radius has bounds from 300 to 400
  erange = 600
  ecastspeed = 0.34 --(s) calculated from tick values before and after cast of even horizon

  ----------------
  --[[  code  ]]--
  ----------------
  --require"comboLib"
  --require"VPrediction"
  stealTarget = nil
  comboArray = {}
  oldname = "default"
  timeoutTick = 0
  requiresW = false
  eTarget = nil
  LastWindUp = 0
  LastAnimationT = 0
  LastAttack = 0


  VeigarConfig = scriptConfig("Veigar Combo", "veigarcombo")
  VeigarConfig:addSubMenu("Combo","Combo")
  VeigarConfig:addSubMenu("Kill Steal","KillSteal")
  VeigarConfig:addSubMenu("Farming","Farming")
  VeigarConfig:addSubMenu("Harass", "Harass")
  VeigarConfig:addSubMenu("Drawing","Drawing")

  VeigarConfig.Combo:addParam("spacebarActive", "Smart Combo", SCRIPT_PARAM_ONKEYDOWN, false, spaceHK)
  VeigarConfig.Combo:addParam("useStunWithSpace", "Use Stun with Combo", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Combo:addParam("fullCombo", "Use All Skills", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
  VeigarConfig.Combo:addParam("comboMoveToMouse","Move to mouse", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Combo:addParam("comboOrbWalk","Orbwalk", SCRIPT_PARAM_ONOFF, true)

  VeigarConfig.KillSteal:addParam("stealOption", "Steal on Killable", SCRIPT_PARAM_ONOFF, false)
  VeigarConfig.KillSteal:addParam("stunWithStealOption", "Use Stun with Steal", SCRIPT_PARAM_ONOFF, true)

  VeigarConfig.Farming:addParam("autoFarmMinions", "Auto-Farm (V)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
  VeigarConfig.Farming:addParam("farmWithQ", "Farm with Q", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Farming:addParam("farmWithW", "Farm with W", SCRIPT_PARAM_ONOFF, false)
  VeigarConfig.Farming:addParam("farmMoveToMouse","Move to mouse", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Farming:addParam("farmConserveMana", "Conserve mana during farm", SCRIPT_PARAM_ONOFF,true)
  VeigarConfig.Farming:addParam("farmConserveManaMax", "Mana % to conserve", SCRIPT_PARAM_SLICE, 20, 1, 100, 0)

  VeigarConfig.Harass:addParam("harassActive","Harass Enemy (C)",SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
  VeigarConfig.Harass:addParam("harassUseQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Harass:addParam("harassUseW", "Use W", SCRIPT_PARAM_ONOFF,false)
  VeigarConfig.Harass:addParam("harassMoveToMouse","Move to mouse", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Harass:addParam("harassConserveMana", "Conserve mana during harass", SCRIPT_PARAM_ONOFF,true)
  VeigarConfig.Harass:addParam("harassConserveManaMax", "Mana % to conserve", SCRIPT_PARAM_SLICE, 20, 1, 100, 0)

  VeigarConfig.Drawing:addParam("drawLagFree","Lag free circles", SCRIPT_PARAM_ONOFF,true)
  VeigarConfig.Drawing:addParam("chordLength","Lag Free Chord Length", SCRIPT_PARAM_SLICE, 75, 75, 2000, 0)
  VeigarConfig.Drawing:addParam("drawKillable", "Draw Killable Hero", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Drawing:addParam("drawKillableMinions","Draw minion killable with Q", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Drawing:addParam("drawQRange", "Draw Q Range", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Drawing:addParam("drawWRange", "Draw W Range", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig.Drawing:addParam("drawERange", "Draw E Range", SCRIPT_PARAM_ONOFF, true)

  VeigarConfig:addParam("eCastActive", "Use E+W", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("E"))
  VeigarConfig:addParam("cageTeamActive", "Cage Team", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("G"))
  VeigarConfig:addParam("packetCast", "Cast spells using packets", SCRIPT_PARAM_ONOFF, true)
  VeigarConfig:addParam("Version", "Version", SCRIPT_PARAM_INFO, version)

  --VeigarConfig:permaShow("autoFarmMinions")
  --VeigarConfig:permaShow("stealOption")


  ts = TargetSelector(TARGET_LOW_HP, erange + eradius, DAMAGE_MAGIC)
  ts.name = "Veigar"

  VP = VPrediction()
  VeigarConfig:addTS(ts)

  function customE()
    if myHero:CanUseSpell(_E) == READY then return true else return false end
  end


  fullCombo = { _Q, _W, _R }
  --combo 1 is the stun combo
  comboLib:newSkill("Q", (wrange + wradius), 1)
  comboLib:newSkill("DFG", (wrange + wradius), 1)
  comboLib:newSkill("HXG", (wrange + wradius), 1)
  comboLib:newSkill("BWC", (wrange + wradius), 1)
  comboLib:newSkill("RUINEDKING", (wrange + wradius), 1)
  comboLib:newSkill("TIAMAT", (wrange + wradius), 1)
  comboLib:newSkill("HYDRA", (wrange + wradius), 1)
  comboLib:newSkill("W", (wrange + wradius), 1, customE, true)
  comboLib:newSkill("R", (wrange + wradius), 1)
  comboLib:newSkill("ignite", (wrange + wradius), 1)
  --global combo 3 for draw killable with stun

  comboLib:newSkill("Q", 30000, 3)
  comboLib:newSkill("W", 30000, 3, customE, true)
  comboLib:newSkill("DFG", 30000, 3)
  comboLib:newSkill("BWC", 30000, 3)
  comboLib:newSkill("RUINEDKING", 30000, 3)
  comboLib:newSkill("TIAMAT", 30000, 3)
  comboLib:newSkill("HYDRA", 30000, 3)
  comboLib:newSkill("HXG", 30000, 3)
  comboLib:newSkill("R", 30000, 3)
  comboLib:newSkill("ignite", 30000, 3)
  --global combo for draw killable without stun


  enemyMinions = minionManager(MINION_ENEMY, qrange, myHero, MINION_SORT_HEALTH_ASC)
  enemyMinions2 = minionManager(MINION_ENEMY,wrange,myHero,MINION_SORT_HEALTH_ASC)
  PrintChat(" <font size = \"30\" color=\"#00CCFF\">>>Veigar's Super FunHouse v"..version.."</font><font size = \"30\" color=\"#00FF00\"> Loaded!</font>")
end

function GetDistanceTo(target1, target2)
  local dis
  if target2 ~= nil and target1 ~= nil then
    dis = math.sqrt((target2.x - target1.x) ^ 2 + (target2.z - target1.z) ^ 2)
  end
  return dis
end

function manaPct()

  return math.round((myHero.mana / myHero.maxMana)*100)

end

function moveToMouse()

  if VIP_USER then
    Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
  else
    myHero:MoveTo(mousePos.x, mousePos.z)
  end
end

function veigOrbWalk()

  local Otarget = ts.target
  if Otarget then
    if os.clock() + GetLatency()/2000 > LastAttack + LastAnimationT and GetDistance(Otarget) < 550 and not _G.evade  then
      Packet('S_MOVE', {type = 3, targetNetworkId=Otarget.networkID}):send()
    elseif os.clock() + GetLatency()/2000 > LastAttack + LastWindUp + 0.05 and not _G.evade then
      Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
    end
  elseif not _G.evade then
    Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
  end
end

function autoHarass()

  if (VeigarConfig.Harass.harassConserveMana and manaPct() > VeigarConfig.Harass.harassConserveManaMax) or not VeigarConfig.HarassConserveMana then
    if VeigarConfig.Harass.harassUseQ then
      if myHero:CanUseSpell(_Q) == READY and ts.target and targetvalid(ts.target) and GetDistance(ts.target) <= qrange then
        UseSpell(_Q, ts.target)
      end
    end

    if VeigarConfig.Harass.harassUseW then
      if myHero:CanUseSpell(_W) == READY and ts.target and targetvalid(ts.target,wrange) and GetDistance(ts.target) <= wrange then
        local spellPos, hitchance = VP:GetCircularCastPosition(ts.target, wcastspeed, wradius, wrange)
        if spellPos and hitchance >= 3 then
         --CastSpell(_W, spellPos.x, spellPos.z)
          UseSpell(_W, spellPos.x, spellPos.z)
        end
      end
    end
  end
end

function UseSpell(Spell,param1,param2)

  if VeigarConfig.packetCast and VIP_USER then
    if param1 and param2 then
      Packet("S_CAST", {spellId = Spell, fromX = param1, fromY = param2, toX = param1, toY = param2}):send()
    elseif param1 then
      Packet("S_CAST", {spellId = Spell, targetNetworkId = param1.networkID}):send()
    else
      Packet("S_CAST", {spellID = Spell, targetNetworkID = myHero.networkID}):send()
    end
  else
    if param1 and param2 then
      CastSpell(Spell,param1,param2)
    elseif param1 then
      CastSpell(Spell,param1)
    else
      CastSpell(Spell)
    end
  end
end

function targetvalid(target)
  return target ~= nil and target.team ~= player.team and target.visible and not target.dead and GetDistanceTo(player, target) <= (erange + eradius)
end

function targetsinradius(target1, target2)
  local dis, dis1, dis2, predicted1, predicted2, hitchance1, hitchance2

  predicted1, hitchance1 = VP:GetPredictedPos(target1, ecastspeed)
  predicted2, hitchance2  = VP:GetPredictedPos(target2, ecastspeed)

  if predicted1 and predicted2 then
    dis = math.sqrt((predicted2.x - predicted1.x) ^ 2 + (predicted2.z - predicted1.z) ^ 2) --find the distance between the two targets

    dis1 = math.sqrt((predicted1.x - player.x) ^ 2 + (predicted1.z - player.z) ^ 2) --distance from player to predicted target 1
    dis2 = math.sqrt((predicted2.x - player.x) ^ 2 + (predicted2.z - player.z) ^ 2) --distance from player to predicted target 2
  end

  return dis ~= nil and dis <= (eradius * 2) and dis1 <= (eradius + erange) and dis2 <= (eradius + erange)
end

function calcdoublestun(target1, target2)

  local CircX, CircZ, predicted1, predicted2, hitchance1, hitchance2

  predicted1, hitchance1 = VP:GetPredictedPos(target1, ecastspeed)
  predicted2, hitchance2  = VP:GetPredictedPos(target2, ecastspeed)

  if predicted1 and predicted2 and (hitchance1 >=2) and (hitchance2 >=2) then

    local h1 = predicted1.x
    local k1 = predicted1.z
    local h2 = predicted2.x
    local k2 = predicted2.z

    local u = (h1) ^ 2 + (h2) ^ 2 - 2 * (h1) * (h2) - (k1) ^ 2 + (k2) ^ 2
    local w = k1 - k2
    local v = h2 - h1

    local a = 4 * (w ^ 2 + v ^ 2)
    local b = 4 * (u * w - 2 * ((v) ^ 2) * (k1))
    local c = (u) ^ 2 - 4 * ((v ^ 2)) * (eradius ^ 2 - k1 ^ 2)

    local Z1 = ((-b) + math.sqrt((b) ^ 2 - 4 * a * c)) / (2 * a) --Z coord for first solution
    local Z2 = ((-b) - math.sqrt((b) ^ 2 - 4 * a * c)) / (2 * a) --Z coord for second solution

    local d = (Z1 - k1) ^ 2 - (eradius) ^ 2
    local e = (Z1 - k2) ^ 2 - (eradius) ^ 2

    local X1 = ((h2) ^ 2 - (h1) ^ 2 - d + e) / (2 * v) -- X Coord for first solution

    local p = (Z2 - k1) ^ 2 - (eradius) ^ 2
    local q = (Z2 - k2) ^ 2 - (eradius) ^ 2

    local X2 = ((h2) ^ 2 - (h1) ^ 2 - p + q) / (2 * v) --X Coord for second solution


    --determine if these 2 points are within range, and which is closest

    local dis1 = math.sqrt((X1 - player.x) ^ 2 + (Z1 - player.z) ^ 2)
    local dis2 = math.sqrt((X2 - player.x) ^ 2 + (Z2 - player.z) ^ 2)

    if dis1 <= (eradius + erange) and dis1 <= dis2 then
      CircX = X1
      CircZ = Z1
    end
    if dis2 <= (eradius + erange) and dis2 < dis1 then
      CircX = X2
      CircZ = Z2
    end
  end
  return CircX, CircZ
end

function calcsinglestun()
  if (ts.target ~= nil) and player:CanUseSpell(SPELL_3) == READY then
    local predicted, hitchance1

    predicted, hitchance1 = VP:GetPredictedPos(ts.target, ecastspeed)


    if predicted and (hitchance1 >=2) then
      local CircX, CircZ
      local dis = math.sqrt((player.x - predicted.x) ^ 2 + (player.z - predicted.z) ^ 2)
      CircX = predicted.x + eradius * ((player.x - predicted.x) / dis)
      CircZ = predicted.z + eradius * ((player.z - predicted.z) / dis)
      return CircX, CircZ
    end
  end
end

function GetNMinionsHit(pos, radius)
  local count = 0
  for i, minion in pairs(enemyMinions2.objects) do
    if GetDistance(minion, pos) < (radius + 50) then
      count = count + 1
    end
  end
  return count
end


function castESpellOnTarget(object)

  if player:CanUseSpell(_E) then

    local target1 = object
    local CircX, CircZ, returnTarget
    local players = heroManager.iCount
    for j = 1, players, 1 do

      local target2 = heroManager:getHero(j)
      if targetvalid(target1) and targetvalid(target2) and target1.name ~= target2.name then --make sure both targets are valid enemies and in spell range
        if targetsinradius(target1, target2) and CircX == nil and CircZ == nil then --true if a double stun is possible

          CircX, CircZ = calcdoublestun(target1, target2) --calculates coords for stun
          if CircX and CircZ then
            break
          end
      end
      end
    end

    if CircX == nil or CircZ == nil then --true if double stun coords were not found
      if targetvalid(object) then
        CircX, CircZ = calcsinglestun() --calculate stun coords for a single target
    end
    end
    if CircX and CircZ then --true if any coords were found
      UseSpell(_E, CircX, CircZ)
    end
  end
end

function useStunCombo(object)
  local spellPos, hitchance
  if player:CanUseSpell(_E) == READY and not object.dead then
    castESpellOnTarget(object)
  end

  if player:CanUseSpell(_W) == READY and not object.dead then
    if object and targetvalid(object) then
      spellPos, hitchance = VP:GetCircularCastPosition(object, wcastspeed, wradius, wrange)
      if spellPos and (hitchance >= 3) then
        UseSpell(_W, spellPos.x, spellPos.z)
        --else
        -- UseSpell(_W, object)
      end
    end
  end
end

function hasW(array)

  local test
  for i = 1, #array, 1 do
    if array[i].skill == _W then
      test = true
    else
      test = test or false
    end
  end
  return test
end

function performcombo(target, stealflag)

  local eComboFlag = false
  if oldname ~= target.name or GetTickCount() > timeoutTick then --find NEW combo if target has changed(dead, out of range) or if all skills in previous combo were used.
    comboArray = comboLib:findBestCombo(target, 1) --find combo
    if comboArray == nil or #comboArray == 0 then --combo not found for target in range
      requiresW = false
      if stealflag == true then
        stealTarget = nil
      end
    elseif comboArray and #comboArray > 0 then --combo without stun worked!
      requiresW = hasW(comboArray)
      oldname = target.name
      timeoutTick = GetTickCount() + comboTimeout
    end
  end
  if comboArray and #comboArray > 0 then

    if requiresW and player:CanUseSpell(_W) == READY and ((VeigarConfig.Combo.spacebarActive and VeigarConfig.Combo.useStunWithSpace) or (VeigarConfig.KillSteal.stealOption and VeigarConfig.Combo.spacebarActive == false and VeigarConfig.KillSteal.stunWithStealOption)) then
      useStunCombo(target)
    else
      eComboFlag = true --E+W has been used
    end

    if eComboFlag == true then
      for i = 1, #comboArray, 1 do
        if player:CanUseSpell(comboArray[i].skill) == READY and comboArray[i].name ~= "W" then
          UseSpell(comboArray[i].skill, target)
        end
      end
    end
  else
    if VeigarConfig.Combo.spacebarActive and not VeigarConfig.Combo.fullCombo and player:CanUseSpell(_Q) == READY then
      UseSpell(_Q, target)
    end
    if VeigarConfig.Combo.fullCombo and VeigarConfig.Combo.spacebarActive == false then
      for i = 1, #fullCombo, 1 do
        if player:CanUseSpell(_W) == READY then
          useStunCombo(target)
        else
          eComboFlag = true
        end
        if eComboFlag == true then
          for i = 1, #fullCombo, 1 do
            if player:CanUseSpell(fullCombo[i]) == READY and fullCombo[i] ~= _W then
              UseSpell(fullCombo[i], target)
            end
          end
        end
      end
    end
  end
  if stealflag == true and not targetvalid(target) then
    stealTarget = nil
  end
end

function autoFarm()

  if VeigarConfig.Farming.farmWithQ then
    enemyMinions:update()
    if enemyMinions.objects[1] then
      local targetMinion = enemyMinions.objects[1]
      if ValidTarget(targetMinion, qrange) and string.find(targetMinion.name, "Minion_") then
        if targetMinion.health < player:CalcMagicDamage(targetMinion, 45 * (player:GetSpellData(_Q).level - 1) + 80 + (.6 * player.ap)) then
          UseSpell(_Q, targetMinion)
        end
      end
    end
  end

  if VeigarConfig.Farming.farmWithW then

    enemyMinions2:update()
    local Max = 0
    local maxPos = nil
    for i, minion in pairs(enemyMinions2.objects) do
      if (GetDistance(minion) < wrange) and (minion.charName:find("Wizard") or minion.charName:find("Caster")) then
        local Count = GetNMinionsHit(minion, wradius)
        if Count > Max then
          Max = Count
          maxPos = Vector(minion.x, 0, minion.z)
        end
      end
    end

    if (Max > 2)  and maxPos then
      UseSpell(_W, maxPos.x, maxPos.z)
    end
  end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
  chordlength = chorlength or VeigarConfig.Drawing.chordLength
  radius = radius or 300
  quality = math.max(8,math.floor(180/math.deg((math.asin((chordlength/(2*radius)))))))
  quality = 2 * math.pi / quality
  radius = radius*.92
  local points = {}
  for theta = 0, 2 * math.pi + quality, quality do
    local c = WorldToScreen(D3DXVECTOR3(x + radius * math.cos(theta), y, z - radius * math.sin(theta)))
    points[#points + 1] = D3DXVECTOR2(c.x, c.y)
  end
  DrawLines2(points, width or 1, color or 4294967295)
end

function CustomDrawCircle(x, y, z, radius, color)
  local vPos1 = Vector(x, y, z)
  local vPos2 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local tPos = vPos1 - (vPos1 - vPos2):normalized() * radius
  local sPos = WorldToScreen(D3DXVECTOR3(tPos.x, tPos.y, tPos.z))

  if not VeigarConfig.Drawing.drawLagFree then  

    return DrawCircle(x, y, z, radius, color)
  end
  if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
    DrawCircleNextLvl(x, y, z, radius, 1, color, 75)
  end
end

function OnDraw()
  local players, drawtarget
  local requiresW = false
  local drawComboArray

  if not player.dead then

    if VeigarConfig.Drawing.drawQRange == true then
      CustomDrawCircle(player.x, player.y, player.z, qrange, qCircleColor)
    end
    if VeigarConfig.Drawing.drawWRange == true then
      CustomDrawCircle(player.x, player.y, player.z, wrange, wCircleColor)
    end
    if VeigarConfig.Drawing.drawERange == true then
      CustomDrawCircle(player.x, player.y, player.z, erange + eradius, eCircleColor)
    end

    if VeigarConfig.Drawing.drawKillableMinions then
      enemyMinions:update()
      if enemyMinions.objects[1] then
        local targetMinion = enemyMinions.objects[1]

        if ValidTarget(targetMinion, erange+eradius) and string.find(targetMinion.name, "Minion_") then
          if targetMinion.health < player:CalcMagicDamage(targetMinion, 45 * (player:GetSpellData(_Q).level - 1) + 80 + (.6 * player.ap)) then
            CustomDrawCircle(targetMinion.x,targetMinion.y,targetMinion.z, 150, qCircleColor)
          end
        end
      end
    end


    if VeigarConfig.Drawing.drawKillable == true then
      players = heroManager.iCount
      for i = 1, players, 1 do
        drawtarget = heroManager:getHero(i)
        if drawtarget ~= nil then
          if drawtarget.team ~= player.team and drawtarget.visible and not drawtarget.dead then

            drawComboArray = comboLib:findBestCombo(drawtarget, 3)
            requiresW =  drawComboArray and hasW(drawComboArray)

            if drawComboArray and #drawComboArray > 0 then
              for j = 0, circleThickness do
                CustomDrawCircle(drawtarget.x, drawtarget.y, drawtarget.z, circleRadius + j * 1.5, drawKillColor1)
              end
              if requiresW == true then
                CustomDrawCircle(drawtarget.x, drawtarget.y, drawtarget.z, 150, drawKillColor2)
              end
            end
          end
        end
      end
    end
  end
end

function OnProcessSpell(unit,spell)
  if unit.isMe then
    if spell.name:lower():find("attack") then
      LastWindUp = spell.windUpTime
      LastAnimationT = spell.animationTime
      LastAttack = os.clock() - GetLatency()/2000
    end
  end
end

function OnTick()
  local players = heroManager.iCount
  ts:update()
  --lp:tick()
  if VeigarConfig.eCastActive == true and not player.dead and VeigarConfig.Combo.spacebarActive == false and VeigarConfig.cageTeamActive == false then
    if eTarget then
      if not targetvalid(eTarget) then
        eTarget = nil
      end
    end
    if eTarget == nil then
      if ts.target then
        eTarget = ts.target
      else
        for i = 1, heroManager.iCount, 1 do
          local testTarget = heroManager:getHero(i)
          if targetvalid(testTarget) then
            eTarget = testTarget
          end
        end
      end
    end

    if eTarget then
      useStunCombo(eTarget)
    end
  end

  if (VeigarConfig.Combo.spacebarActive == true or VeigarConfig.Combo.fullCombo == true) and not player.dead and VeigarConfig.eCastActive == false and VeigarConfig.cageTeamActive == false then
    if targetvalid(ts.target) and ts.target.bMagicImunebMagicImune ~= true and ts.target.bInvulnerable ~= true then
      performcombo(ts.target, false)
      if VeigarConfig.Combo.comboOrbWalk then
        veigOrbWalk()
      end
    elseif VeigarConfig.Combo.comboMoveToMouse then
      moveToMouse()
    end
  end


  if VeigarConfig.KillSteal.stealOption == true and not player.dead and VeigarConfig.Combo.spacebarActive == false and VeigarConfig.eCastActive == false and VeigarConfig.cageTeamActive == false then
    if stealTarget == nil then
      for i = 1, players, 1 do
        local testTarget = heroManager:getHero(i)
        if targetvalid(testTarget) and testTarget.bMagicImunebMagicImune ~= true and testTarget.bInvulnerable ~= true then
          stealTarget = testTarget
          performcombo(stealTarget, true)
        end
      end
    else
      performcombo(stealTarget, true)
    end
  end


  if VeigarConfig.cageTeamActive == true and ts.target ~= nil and not player.dead then
    local spellPos = FindGroupCenterFromNearestEnemies(eradius, erange)
    if spellPos ~= nil then
      UseSpell(_E, spellPos.center.x, spellPos.center.z)
    end
  end


  if VeigarConfig.Farming.autoFarmMinions == true and not player.dead and not VeigarConfig.Combo.spacebarActive and not VeigarConfig.eCastActive then
    if (VeigarConfig.Farming.farmConserveMana and manaPct() > VeigarConfig.Farming.farmConserveManaMax) or not VeigarConfig.Farming.farmConserveMana then
      autoFarm()
    end
    if VeigarConfig.Farming.farmMoveToMouse then
      moveToMouse()
    end
  end

  if VeigarConfig.Harass.harassActive and not player.dead and not VeigarConfig.Combo.spacebarActive and not VeigarConfig.eCastActive  then
    autoHarass()
    if VeigarConfig.Harass.harassMoveToMouse and not VeigarConfig.Harass.harassOrbWalk then
      moveToMouse()
    elseif VeigarConfig.Harass.harassOrbWalk then
      veigOrbWalk()
    end

  end
end


class'Circle'
function Circle:__init(center, radius)
  assert((VectorType(center) or center == nil) and (type(radius) == "number" or radius == nil), "Circle: wrong argument types (expected <Vector> or nil, <number> or nil)")
  self.center = Vector(center) or Vector()
  self.radius = radius or 0
end

function Circle:Contains(v)
  assert(VectorType(v), "Contains: wrong argument types (expected <Vector>)")
  return math.close(self.center:dist(v), self.radius)
end

function Circle:__tostring()
  return "{center: " .. tostring(self.center) .. ", radius: " .. tostring(self.radius) .. "}"
end
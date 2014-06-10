local version = 2.3
-- Diana  Moonraker edition

--[[


TODO:

Add mana checks for jumping
Add escape movements
ADD use R for minion farming
ADD move to mouse for minion farming
Currently, the enemy can get away when a letal R is ready but not Q.  IF lethal R, no Q, go ahead and use Q?
Line 353, qPred only happens when target is in qRange, we need another qPred for when target is 2*qRange. Will need
a new velocity and qdelay*2.5 or so.

]]--


if myHero.charName ~= "Diana" then return end



--[[   Vars  ]] --

local thetaIterator = 4 --increase to improve performance (0 - 10)
local rangeIterator = 30 --increase to improve performance (from 0-100)
local roundRange = 100 --higher means more minions collected, but possibly less accurate.

local drawQColor = ARGB(255,0,0,255) --blue
local drawEColor = ARGB(255,0,100,255) --green
local drawKillColor = ARGB(255,255,0,0) --red
local drawKillMinionColor = ARGB(255,0,255,0) -- green


local qPred
local ts
local qRange = 900
local aaRange = 400
local wRange = 250
local eRange = 450
local eBuffer = 225
local rRange = 825

--[[    Moonlight       ]] --
local MoonLightEnemy = {}
local MoonLightTS = 0
local MoonLight = false
--[[    Damage Calculation      ]] --
local waittxt = {}
local calculationenemy = 1
local floattext = { "Skills are not available", "Able to fight", "Killable", "Murder him!" }
local killable = {}

--[[    Ready   ]] --
local ignite
local QREADY, WREADY, EREADY, RREADY = false, false, false, false
local BRKSlot, DFGSlot, HXGSlot, BWCSlot, TMTSlot, RAHSlot, RNDSlot, YGBSlot
local BRKREADY, DFGREADY, HXGREADY, BWCREADY, TMTREADY, RAHREADY, RNDREADY, YGBREADY, IREADY = false, false, false, false, false, false, false, false, false


--------------------------
--[[  Q Calculations  ]] --
local rangeMax = 830 --default
local qDelay = 0.35 --seconds
local qSpeed = 1800
local qWidth = 10
local enemyMinions = {}
local accel = -1483
local highestCollision
local highestAngle
local highestRange
local MODE_MINION = 1
local MODE_CHAMP = 2
--------------------------
--[[    Prediction      ]] --
--------------------------
local AttackDelayLatency = 1000
local lastBasicAttack = 0
local swingDelay = 1000
local useRTimeout = 3000
local useRTimer = 0



local HitBoxSize = GetDistance(myHero.minBBox)
local shotFired = false
local animationEnd = true
local animationTimer = 0
local mainTimer = GetTickCount()
local rtarget

--[[ Acrobatics ]]--

local jungleMinions
local misayaComboing = false
local misayaTick = 0
local misayaTimeout = 1000 --ms
local JungleMoonlight = {}
local jumpTarget, jumpFlag
local jumpingToTarget = false
local jumpMouseDistance = 300
local jumpTargetTick = 0
local jumpTargetTimeout = 2000
local wallJumps = {}


local DownloadSourceLib = false
local prodictionLoaded = false


function autoUpdate()

  AUTOUPDATE = true
  SCRIPT_NAME = "Diana - Moonraker Edition"
  UPDATE_HOST = "raw.github.com"
  UPDATE_PATH = "/LlamaBoL/BoL/master/Diana - Moonraker Edition.lua".."?rand="..math.random(1,10000)
  UPDATE_URL = "https://"..UPDATE_HOST..UPDATE_PATH
  VERSION_PATH = "LlamaBoL/BoL/master/Version/"..SCRIPT_NAME..".version"
  SOURCELIB_URL = "https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua"
  SOURCELIB_PATH = LIB_PATH.."SourceLib.lua"

  if FileExist(SOURCELIB_PATH) then
    require("SourceLib")
  else
    DownloadSourceLib = true
    DownloadFile(SOURCELIB_URL, SOURCELIB_PATH, function() PrintChat("SourceLib downloaded, please reload (F9)") end)
  end

  if DownloadSourceLib then print("Downloading required libraries, please wait...") return end

  if AUTOUPDATE then
    SourceUpdater(SCRIPT_NAME, version, UPDATE_HOST,UPDATE_PATH, SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, VERSION_PATH):CheckUpdate()
  end

  libDownload = Require("SourceLib")
  libDownload:Add("vPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
  libDownload:Add("SOW", "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
  libDownload:Check()

  if libDownload.downloadNeeded == true then return end

  if VIP_USER then
    if FileExist(SCRIPT_PATH..'Common/Prodiction.lua') then
      require "Prodiction"
      prodictionLoaded = true
    end
  end
end

function GetDistance(p1, p2)
  if (p1 and p2 and p1.x and p1.z and p2.x and p2.z) then
    return math.sqrt((p1.x-p2.x)^2+(p1.z-p2.z)^2)
  elseif (p1 and p1.x and p1.z) then
    return math.sqrt((myHero.x-p1.x)^2+(myHero.z-p1.z)^2)
  else
    return math.huge
  end
end

function initMinions()

  enemyMinions = minionManager(MINION_ENEMY, rangeMax, player, MINION_SORT_HEALTH_ASC)
  jungleMinions = minionManager(MINION_JUNGLE, rangeMax, player, MINION_SORT_HEALTH_ASC)
  JungleData = {}
  JungleMonsters = {}
  --Jungle = self
  makeJungleData()

  for i = 0, objManager.maxObjects do
    local object = objManager:getObject(i)
    if object and object.name and string.find(object.name,"monsterCamp_") then
      table.insert(wallJumps,object)
    end
    if isJungleMinion(object) then
      table.insert(JungleMonsters, object)
    end
  end

end

function initMenu()

  DCConfig = scriptConfig("Diana Combo", "DianaCombo")
  DCConfig:addSubMenu("Normal Combo","NormalCombo")
  DCConfig:addSubMenu("Misaya Combo","MisayaCombo")
  DCConfig:addSubMenu("Kill Steal","KillSteal")
  DCConfig:addSubMenu("Harass","Harassing")
  DCConfig:addSubMenu("Farming","Farming")
  DCConfig:addSubMenu("Jungle","Jungle")
  DCConfig:addSubMenu("Drawing","Drawing")
  DCConfig:addSubMenu("Misc","Misc")
  DCConfig:addSubMenu("Performance/Accuracy","Performance")
  DCConfig:addSubMenu("Prediction","Prediction")


  DCConfig.NormalCombo:addParam("BurstCombo", "Full Combo", SCRIPT_PARAM_ONKEYDOWN, false, 32)
  DCConfig.NormalCombo:addParam("orbWalk", "Orb Walk", SCRIPT_PARAM_ONOFF, true)
  DCConfig.NormalCombo:addParam("useItems", "Use Items", SCRIPT_PARAM_ONOFF, true)
  DCConfig.NormalCombo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
  DCConfig.NormalCombo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
  --DCConfig.NormalCombo:addParam("jumpToTarget", "Jump to Distant Kill", SCRIPT_PARAM_ONOFF, true)
  --DCConfig.NormalCombo:addParam("onlyJumpIfKillable", "Only Jump If Killable", SCRIPT_PARAM_ONOFF, true)

  DCConfig.MisayaCombo:addParam("BurstCombo", "Misaya Combo", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
  DCConfig.MisayaCombo:addParam("orbWalk", "Orb Walk", SCRIPT_PARAM_ONOFF, true)
  DCConfig.MisayaCombo:addParam("useItems", "Use Items", SCRIPT_PARAM_ONOFF, true)
  DCConfig.MisayaCombo:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
  DCConfig.MisayaCombo:addParam("useE", "Use E", SCRIPT_PARAM_ONOFF, true)
  --DCConfig.MisayaCombo:addParam("jumpToTarget", "Jump to Distant Kill", SCRIPT_PARAM_ONOFF, true)
  --DCConfig.MisayaCombo:addParam("onlyJumpIfKillable", "Only Jump If Killable", SCRIPT_PARAM_ONOFF, true)

  DCConfig.KillSteal:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, false)
  DCConfig.KillSteal:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, false)
  --DCConfig.KillSteal:addParam("useMisaya", "Use Misaya", SCRIPT_PARAM_ONOFF, false)

  DCConfig.Harassing:addParam("enabled", "Harass", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
  DCConfig.Harassing:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
  --DCConfig.Harassing:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, false)
  DCConfig.Harassing:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)


  DCConfig.Farming:addParam("autoMinion", "Q Minions", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("X"))
  --DCConfig.Farming:addParam("moveToMouse", "Move To Mouse", SCRIPT_PARAM_ONOFF, true)


  DCConfig.Jungle:addParam("enabled", "Farm Jungle", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("Z"))
  DCConfig.Jungle:addParam("useQ", "Use Q", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Jungle:addParam("useW", "Use W", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Jungle:addParam("useR", "Use R", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Jungle:addParam("orbWalk", "Orb Walk", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Jungle:addParam("jumpToMinion","Jump to Hidden Minions", SCRIPT_PARAM_ONOFF,true)


  DCConfig.Drawing:addParam("lagFree", "Lag Free Circles", SCRIPT_PARAM_ONOFF, false)
  DCConfig.Drawing:addParam("drawCirclesSelf", "Draw Circles - Self", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Drawing:addParam("drawCirclesEnemy", "Draw Circles - Enemy", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Drawing:addParam("drawCirclesMinions","Draw Circles - Minions",SCRIPT_PARAM_ONOFF,true)
  DCConfig.Drawing:addParam("drawText", "Draw Text - Enemy", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Drawing:addParam("wallJumps", "Draw Wall Jumps", SCRIPT_PARAM_ONOFF, true)
  --DCConfig.Drawing:addParam("debug1111", "Color Picker", SCRIPT_PARAM_COLOR, {255, 255, 255, 255})

  DCConfig.Misc:addParam("autoIgnite", "Auto Ignite", SCRIPT_PARAM_ONOFF, true)
  DCConfig.Misc:addParam("rangeMax","Max Range for Q",SCRIPT_PARAM_SLICE,rangeMax,1,830,0)
  DCConfig.Misc:addParam("jumpMouseDistance","Jump Mouse Distance",SCRIPT_PARAM_SLICE,jumpMouseDistance,1,600,0)
  DCConfig.Misc:addParam("usePacket", "Use Packets (VIP only)", SCRIPT_PARAM_ONOFF, true)

  DCConfig.Performance:addParam("info1"," Increase will INCREASE performance but LOWER accuracy",SCRIPT_PARAM_INFO,"")
  DCConfig.Performance:addParam("thetaIterator","Theta",SCRIPT_PARAM_SLICE,thetaIterator,1,10,0)
  DCConfig.Performance:addParam("rangeIterator","Range",SCRIPT_PARAM_SLICE,rangeIterator,1,100,0)
  DCConfig.Performance:addParam("roundRange","Rounding",SCRIPT_PARAM_SLICE,roundRange,1,200,0)

  if VIP_USER and prodictionLoaded then
    DCConfig.Prediction:addParam("predictionList", "Type", SCRIPT_PARAM_LIST, 3, {"FreePrediction", "VPrediction", "Prodiction"})
  else
    DCConfig.Prediction:addParam("predictionList", "Type", SCRIPT_PARAM_LIST, 2, {"FreePrediction","VPrediction"})
  end


end

function initPrediction()

  if prodictionLoaded then
    Prodiction = ProdictManager.GetInstance()
    ProdictionQ = Prodiction:AddProdictionObject(_Q, qRange, qSpeed, qDelay, qWidth)
  end
  FreePredictionQ = TargetPrediction(qRange, (qSpeed / 1000), (qDelay * 1000), qWidth)
  VP = VPrediction()

  ts = TargetSelector(TARGET_LOW_HP_PRIORITY, rRange, DAMAGE_MAGIC)
  ts.name = "Diana"
  DCConfig:addTS(ts)

end

function initSpellData()

  if myHero:GetSpellData(SUMMONER_1).name:find("SummonerDot") then ignite = SUMMONER_1
  elseif myHero:GetSpellData(SUMMONER_2).name:find("SummonerDot") then ignite = SUMMONER_2
  end

end

function OnLoad()


  autoUpdate()
  initMinions()
  initMenu()
  initPrediction()
  initSpellData()

  for i = 1, heroManager.iCount do
    MoonLightEnemy[i] = 0
    waittxt[i] = i * 3
  end

  PrintChat("Diana - Moonraker Edition v"..version.." loaded!")
end

function OnTick()
  qPred = nil

  cleanJungleData()

  if GetTickCount() - animationTimer > AttackDelayLatency then
    animationEnd = false
  end
  AttackDelayLatency = ((1000 * (-0.435 + (0.625 / 0.625))) / (myHero.attackSpeed / (1 / 0.625))) - GetLatency() * 2

  ts:update()
  ReadyCheck()

  if ts.target and GetDistance(ts.target) < rangeMax*2 then
    qPred = getQPrediction(ts.target)
  end

  --[[ Minion Farm ]]--
  if DCConfig.Farming.autoMinion then
    minionFarm()
  end

  --[[ Jungle Farm ]]--
  if DCConfig.Jungle.enabled then
    jungleFarm()
  end


  --[[Normal and Misaya Combo]]--

  if (DCConfig.NormalCombo.BurstCombo or DCConfig.MisayaCombo.BurstCombo) and ts.target and qPred then
    if ((DCConfig.NormalCombo.jumpToTarget or DCConfig.MisayaCombo.jumpToTarget) and requiresJumpToTarget(qPred)) or jumpingToTarget then
      PrintChat("jump1")
      local normFlag = killTargetWithJumpTarget(ts.target)
      if normFlag == true then   --true if target killable by AD+R+W+Items+Ignite
        PrintChat("jump")
        performJumpToTarget(qPred)
      end
    elseif GetDistance(qPred) < rangeMax then
      if DCConfig.NormalCombo.useItems or DCConfig.MisayaCombo.useItems then
        UseItems(ts.target)
      end
      CrescentCollision(MODE_CHAMP)
      if DCConfig.NormalCombo.BurstCombo then
        BurstCombo(ts.target)
      elseif DCConfig.MisayaCombo.BurstCombo then
        MisayaCombo(ts.target)
      end
    end
  elseif heroCanMove() and ((DCConfig.NormalCombo.BurstCombo and DCConfig.NormalCombo.orbWalk) or (DCConfig.MisayaCombo.BurstCombo and DCConfig.MisayaCombo.orbWalk)) then
    moveToMouse()
  end

  --[[   Harass  ]] --
  if DCConfig.Harassing.enabled and ts.target and qPred and GetDistance(qPred) < rangeMax then
    Harass(ts.target)
  elseif DCConfig.Harassing.enabled and heroCanMove() and DCConfig.Harassing.moveToMouse then
    moveToMouse()
  end

  --[[    Ignite  ]] --
  if DCConfig.Misc.autoIgnite and ts.target then
    AutoIgnite()
  end
  if ts.target and (DCConfig.KillSteal.useR and RREADY) or (DCConfig.KillSteal.useQ and QREADY) then
    ultKillSteal()
  end
end

function cleanJungleData()
  for i = 1, #JungleMonsters do
    if not JungleMonsters[i] or not JungleMonsters[i].health or math.floor(JungleMonsters[i].health) == 0 then
      table.remove(JungleMonsters,i)
    end
  end

end

function minionFarm()

  enemyMinions:update()
  CrescentCollision(MODE_MINION)
  if highestCollision > 0 and highestRange > 0 then
    UseSpell(_Q, myHero.x + highestRange * math.cos(highestAngle), myHero.z + highestRange * math.sin(highestAngle))
  elseif #enemyMinions.objects == 1 then
    UseSpell(_Q, enemyMinions.objects[1].x, enemyMinions.objects[1].z)
  end

end

function jungleFarm()
  local jungleTarget = getJungleMonster()

  if jungleTarget and ValidTarget(jungleTarget,rangeMax*2) then
    if QREADY and DCConfig.Jungle.useQ and GetDistance(jungleTarget) <= qRange then
      UseSpell(_Q, jungleTarget.x, jungleTarget.z)
    elseif WREADY and DCConfig.Jungle.useW and GetDistance(jungleTarget) < wRange then
      UseSpell(_W)
    elseif RREADY and DCConfig.Jungle.useR and GetDistance(jungleTarget) < rRange and hasMoonLight(jungleTarget) and  (GetTickCount() > useRTimer + useRTimeout) then --will R to target if moonlight buff
      UseSpell(_R, jungleTarget)
      moonLight = true
      useRTimer = GetTickCount()
    elseif DCConfig.Jungle.orbWalk and GetDistance(jungleTarget) <= getMyTrueRange() then
      if timeToShoot() or shotFired == true then
        attackEnemy(jungleTarget)
      else
        if heroCanMove() then
          moveToMouse()
        end
      end
    elseif heroCanMove() and DCConfig.Jungle.orbWalk then
      moveToMouse()
    end
  else --no jungle target visible
    if DCConfig.Jungle.jumpToMinion and RREADY and QREADY then
      useQOnHiddenJungleMinion()
  end
  if DCConfig.Jungle.orbWalk then
    moveToMouse()
  end
  end
end

function useQOnHiddenJungleMinion()
  for i = 1, #wallJumps do
    if (GetDistance(wallJumps[i],mousePos) < DCConfig.Misc.jumpMouseDistance) and (GetDistance(wallJumps[i]) < qRange+100) and GetDistance(wallJumps[i]) > DCConfig.Misc.jumpMouseDistance then
      if QREADY and RREADY then
        UseSpell(_Q, wallJumps[i].x, wallJumps[i].z)
      end
    end
  end
end

function UseSpell(Spell,param1,param2)

  if DCConfig.Misc.usePacket and VIP_USER then
    if param1 and param2 then
      _CastSpellWithPacket(Spell,param1,param2,nil)
    elseif param1 then
      _CastSpellWithPacket(Spell,nil,nil,param1)
    else
      _CastSpellWithPacket(Spell,nil,nil,myHero)
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

function _CastSpellWithPacket(mySpell, PosX, PosZ, CUnit)
  local tnid, tposX, tposZ = nil, nil, nil
  local cansend = false
  if PosX ~= nil and PosZ ~= nil then
    tposX = PosX
    tposZ = PosZ
    cansend = true
  else
    if CUnit ~= nil then
      tposX = CUnit.x
      tposZ = CUnit.z
      tnid  = CUnit.networkID
      cansend = true
    else
      cansend = false
    end
  end
  if cansend then
    local CSOpacket = CLoLPacket(153)
    CSOpacket.dwArg1 = 1
    CSOpacket.dwArg2 = 0
    CSOpacket:EncodeF(myHero.networkID)
    CSOpacket:Encode1(mySpell)
    CSOpacket:EncodeF(tposX)
    CSOpacket:EncodeF(tposZ)
    CSOpacket:EncodeF(tposX)
    CSOpacket:EncodeF(tposZ)
    if tnid~=nil then
      CSOpacket:EncodeF(tnid)
    else
      CSOpacket:EncodeF(0)
    end
    SendPacket(CSOpacket)
  end
  if not cansend then print("<font color='#F72828'>[CSOP][ERROR]Failed</font>") end
end

function MisayaCombo(target)

  -- R to target, then Q, W, E
  local qMisayaRange = 400
  if GetTickCount() > misayaTick + misayaTimeout then
    misayaComboing = false
  end

  if RREADY and GetDistance(target) < rRange then
    if QREADY then
      UseSpell(_R,target)
      UseSpell(_Q,target)
      misayaComboing = true
      misayaTick = GetTickCount()
      --elseif hasMoonLight(target) then
      --  UseSpell(_R,target)
      --  misayaComboing = false
    end
  end
  if QREADY and GetDistance(target) < qMisayaRange and misayaComboing then --VP:IsDashing(myHero,0,100,math.huge,myHero)
    UseSpell(_Q,target)
    misayaComboing = false
  end
  if DCConfig.MisayaCombo.useW and GetDistance(target) < wRange then  --and not I_AM_DASHING
    UseSpell(_W)
  end
  if DCConfig.MisayaCombo.useE and GetDistance(target) < eRange then
    UseSpell(_E)
  end
  if DCConfig.MisayaCombo.orbWalk and target and isEnemyInAttackRange(target) then
    if timeToShoot() or shotFired == true then
      attackEnemy(target)
    else
      if heroCanMove() and DCConfig.MisayaCombo.orbWalk then
        moveToTarget(target)
      end
    end
  elseif heroCanMove() and DCConfig.MisayaCombo.orbWalk then
    if target then
      moveToTarget(target)
    else
      moveToMouse()
    end
  end
end

function attackedSuccessfully()
  shotFired = false
  lastBasicAttack = GetTickCount()
end

function attackEnemy(enemy)
  if enemy.dead or not enemy.valid then return end
  myHero:Attack(enemy)
  shotFired = true
end

function findMinionBetweenTarget(target)

  local jumpOptions = {}
  local jumpTarget
  local wallJumpFlag = false

  for i = 1, heroManager.iCount do  --find champs in middle of target
    local jumpTarget = heroManager:GetHero(i)
    if ValidTarget(jumpTarget) then
      local castPos = getQPrediction(jumpTarget)
      if castPos and (GetDistance(castPos) < rRange) and (GetDistance(castPos,jumpTarget) < rRange) then
        return castPos, wallJumpFlag
      end
    end
  end

  for i = 1, #wallJumps do  --find jungle targets in middle of target
    jumpTarget = wallJumps[i]
    if (GetDistance(jumpTarget) < rRange) and (GetDistance(jumpTarget,target) < rRange) then
      wallJumpFlag = true
      return jumpTarget, wallJumpFlag
    end
  end

  enemyMinions:update()
  for i = 1, #enemyMinions do  --find minion targets in middle of target
    jumpTarget = enemyMinions.object[i]
    local castPos = getQPrediction(jumpTarget)
    if castPos and (GetDistance(castPos) < rRange) and (GetDistance(castPos,jumpTarget) < rRange) then
      return castPos, wallJumpFlag
    end
  end
end

function requiresJumpToTarget(target)

  return RREADY and QREADY and (GetDistance(target) < rRange*2) and (GetDistance(target) > rRange)
end

function killTargetWithJumpTarget(enemy) --returns 1 = R,  2 = R,W  3 = R,W,items  4 = R,W,items,ignite

  if DCConfig.NormalCombo.onlyJumpIfKillable or DCConfig.MisayaCombo.onlyJumpIfKillable then

    local ignitedamage, dfgdamage, hxgdamage, bwcdamage, brkdamage, tmtdamage, rahdamage = 0, 0, 0, 0, 0, 0, 0
    local pdamage = getDmg("P", enemy, myHero)
    --local qdamage = getDmg("Q", enemy, myHero)
    local wdamage = getDmg("W", enemy, myHero)
    local rdamage = getDmg("R", enemy, myHero, 1)
    local hitdamage = getDmg("AD", enemy, myHero)
    local ignitedamage = (ignite and getDmg("IGNITE", enemy, myHero) or 0)
    local dfgdamage = (DFGSlot and getDmg("DFG", enemy, myHero) or 0)
    local hxgdamage = (HXGSlot and getDmg("HXG", enemy, myHero) or 0)
    local bwcdamage = (BWCSlot and getDmg("BWC", enemy, myHero) or 0)
    local brkdamage = (BRKSlot and getDmg("RUINEDKING", enemy, myHero) or 0)
    local tmtdamage = (TMTSlot and getDmg("TIAMAT", enemy, myHero) or 0)
    local rahdamage = (RAHSlot and getDmg("HYDRA", enemy, myHero) or 0)
    local combo1 = hitdamage * 2 + pdamage  --R
    local combo2 = hitdamage * 2 + pdamage  --R,W
    local combo3 = hitdamage * 2 + pdamage  --R,W, items
    local combo4 = hitdamage * 2 + pdamage  --R,W, items, ignite
    if WREADY then
      combo2 = combo2 + wdamage
      combo3 = combo3 + wdamage
      combo4 = combo4 + wdamage
    end
    if RREADY then
      combo1 = combo1 + rdamage
      combo2 = combo2 + rdamage
      combo3 = combo3 + rdamage
      combo4 = combo4 + rdamage
    end
    if DFGREADY then
      combo3 = combo3 + dfgdamage
      combo4 = combo4 + dfgdamage
    end
    if HXGREADY then
      combo3 = combo3 + hxgdamage
      combo4 = combo4 + hxgdamage
    end
    if BWCREADY then
      combo3 = combo3 + bwcdamage
      combo4 = combo4 + bwcdamage
    end
    if BRKREADY then
      combo3 = combo3 + brkdamage
      combo4 = combo4 + brkdamage
    end
    if TMTREADY then
      combo3 = combo3 + tmtdamage
      combo4 = combo4 + tmtdamage
    end
    if RAHREADY then
      combo3 = combo3 + rahdamage
      combo4 = combo4 + rahdamage
    end
    if IREADY then
      combo4 = combo4 + ignitedamage
    end
    if     combo1 >= enemy.health then return true, 1
    elseif combo2 >= enemy.health then return true, 2
    elseif combo3 >= enemy.health then return true, 3
    elseif combo4 >= enemy.health then return true, 4
    else return false end
else return true end
end

function AddJungleMonster(Name, Priority)
  JungleData[Name] = Priority
end

function makeJungleData()
  AddJungleMonster("Worm12.1.1",             1)              -- Baron
  AddJungleMonster("Dragon6.1.1",            1)              -- Dragon
  AddJungleMonster("AncientGolem1.1.1",      1)              -- Blue Buff Blue side
  AddJungleMonster("AncientGolem7.1.1",      1)              -- Blue Buff Purp side
  AddJungleMonster("YoungLizard1.1.2",       2)              -- Blue Buff Add Blue side
  AddJungleMonster("YoungLizard1.1.3",       2)              -- Blue Buff Add Blue side
  AddJungleMonster("YoungLizard7.1.3",       2)              -- Blue Buff Add Purp side
  AddJungleMonster("YoungLizard7.1.2",       2)              -- Blue Buff Add Purp side
  AddJungleMonster("LizardElder4.1.1",       1)              -- Red Buff Blue side
  AddJungleMonster("LizardElder10.1.1",      1)              -- Red Buff Purp side
  AddJungleMonster("YoungLizard4.1.2",       2)              -- Red Buff Add Blue side
  AddJungleMonster("YoungLizard4.1.3",       2)              -- Red Buff Add Blue side
  AddJungleMonster("YoungLizard10.1.2",      2)              -- Red Buff Add Purp
  AddJungleMonster("YoungLizard10.1.3",      2)              -- Red Buff Add Purp
  AddJungleMonster("GiantWolf2.1.1",         1)              -- Big Wolf Blue side
  AddJungleMonster("GiantWolf8.1.1",         1)              -- Big Wolf Purp Side
  AddJungleMonster("Wolf2.1.2",              2)              -- Small Wolf Blue side
  AddJungleMonster("Wolf2.1.3",              2)              -- Small Wolf Blue side
  AddJungleMonster("Wolf8.1.2",              2)              -- Small Wolf Purp side
  AddJungleMonster("Wolf8.1.3",              2)              -- Small Wolf Purp side
  AddJungleMonster("Wraith3.1.1",            1)              -- Big Wraith Blue side
  AddJungleMonster("Wraith9.1.1",            1)              -- Big Wraith Purp side
  AddJungleMonster("GreatWraith13.1.1",      1)              -- Single Wraith Blue side
  AddJungleMonster("GreatWraith14.1.1",      1)              -- Single Wraith Purp side
  AddJungleMonster("LesserWraith3.1.2",      2)              -- Small Wraith Blue side
  AddJungleMonster("LesserWraith3.1.3",      2)              -- Small Wraith Blue side
  AddJungleMonster("LesserWraith3.1.4",      2)              -- Small Wraith Blue side
  AddJungleMonster("LesserWraith9.1.2",      2)              -- Small Wraith Purp side
  AddJungleMonster("LesserWraith9.1.3",      2)              -- Small Wraith Purp side
  AddJungleMonster("LesserWraith9.1.4",      2)              -- Small Wraith Purp side
  AddJungleMonster("Golem5.1.2",             1)              -- Big Golem Blue side
  AddJungleMonster("Golem11.1.2",            1)              -- Big Golem Purp side
  AddJungleMonster("SmallGolem5.1.1",        2)              -- Small Golem Blue side
  AddJungleMonster("SmallGolem11.1.1",       2)              -- Small Golem Purp side
end

function GetJunglePriority(Name)
  return JungleData[Name]
end

function getJungleMonster()

  local HighestPriorityMonster =  nil
  local Priority = 0

  for _, Monster in pairs(JungleMonsters) do
    if GetDistance(Monster) < rRange then
      local CurrentPriority = GetJunglePriority(Monster.name)
      if Monster.health < getDmg("AD", Monster, myHero) then
        return Monster
      elseif not HighestPriorityMonster then
        HighestPriorityMonster = Monster
        Priority = CurrentPriority
      else
        if CurrentPriority < Priority then
          HighestPriorityMonster = Monster
          Priority = CurrentPriority
        end
      end
    end
  end
  return HighestPriorityMonster
end

function moveToMouse()

  if VIP_USER then
    Packet('S_MOVE', {type = 2, x = mousePos.x, y = mousePos.z}):send()
  else
    myHero:MoveTo(mousePos.x, mousePos.z)
  end
end

function moveToTarget(target)

  if VIP_USER then
    Packet('S_MOVE', {type = 3, targetNetworkId=target.networkID}):send()
  else
    myHero:MoveTo(target.x, target.z)
  end


end

function heroCanMove()
  return not _G.evade and (timeToShoot() or (not shotFired and GetTickCount() - lastBasicAttack > AttackDelayLatency / 2))
end

function timeToShoot()
  return (GetTickCount() > lastBasicAttack + AttackDelayLatency)
end

function isEnemyInAttackRange(enemy)
  local enemyTrueDistance
  if enemy ~= nil then
    if getDistanceOffset(enemy) > 0 then
      enemyTrueDistance = GetDistance(enemy) + getDistanceOffset(enemy) - getHitBoxRadius(enemy)
    else
      enemyTrueDistance = GetDistance(enemy) - getHitBoxRadius(enemy)
    end
    return (enemyTrueDistance < getMyTrueRange())
  end
end

function isJungleMinion(Object)
  return Object and Object.name and JungleData[Object.name] ~= nil
end

function getDistanceOffset(enemy)
  local distance = GetDistance(enemy) - getHitBoxRadius(enemy) + 60
  if distance > getMyTrueRange() then return 0 end
  return distance / 9.85
end

function getHitBoxRadius(target)
  return GetDistance(target.maxBBox, target.minBBox) / 2
end

function getMyTrueRange()
  return getRange() + HitBoxSize
end

function getRange()
  return myHero.range
end

function performJumpToTarget(target)

  if GetTickCount() > jumpTargetTick + jumpTargetTimeout then
    jumpTargetTick = GetTickCount()
    jumpingToTarget = false
  end
  if jumpingToTarget == false then
    jumpTarget, jumpFlag = findMinionBetweenTarget(target)
    if jumpTarget and jumpFlag then
      jumpingToTarget = true
    end
  else
    if jumpFlag == true then --Using wall jump

      if QREADY then UseSpell(_Q, jumpTarget.x, jumpTarget.z) end

      local jungleMinion = getJungleMonster()

      if RREADY and jungleMinion and GetDistance(jungleMinion,jumpTarget) < 100 and hasMoonLight(jungleMinion) then
        UseSpell(_R,jungleMinion)
      end

      if jungleMinion and GetDistance(jumpTarget) < 50 then --minion is visible, hero is next to it.
        jumpingToTarget = false
      end
    else  --using minion jump
      UseSpell(_R, minion.x, minion.z)
      UseSpell(_Q,minion.x, minion.z)
      if GetDistance(jumpTarget) <50 then --Hero is next to minion.
        jumpingToTarget = false
      end
    end
  end
end

function DrawCircleNextLvl(x, y, z, radius, width, color, chordlength)
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
  if not DCConfig.Drawing.lagFree then
    return DrawCircle(x, y, z, radius, color)
  end
  if OnScreen({ x = sPos.x, y = sPos.y }, { x = sPos.x, y = sPos.y })  then
    DrawCircleNextLvl(x, y, z, radius, 1, color, 75)
  end


end

function OnDraw()
  if tick == nil or GetTickCount() - tick >= 100 then
    tick = GetTickCount()
    DmgCalculation()
  end

  if DCConfig.Drawing.drawCirclesSelf and not myHero.dead then
    if QREADY then CustomDrawCircle(myHero.x, myHero.y, myHero.z, qRange, drawQColor) end
    if EREADY then CustomDrawCircle(myHero.x, myHero.y, myHero.z, eRange, drawEColor) end
  end
  if DCConfig.Drawing.drawCirclesEnemy and ts.target ~= nil and GetDistance(ts.target) < rangeMax then
    for j = 0, 10 do
      CustomDrawCircle(ts.target.x, ts.target.y, ts.target.z, 40 + j * 1.5, drawKillColor)
    end
  end
  if DCConfig.Drawing.drawCirclesMinions then
    enemyMinions:update()
    if enemyMinions.objects[1] then
      local targetMinion = enemyMinions.objects[1]
      if ValidTarget(targetMinion, DCConfig.Misc.rangeMax) then --and string.find(targetMinion.name, "Minion_") then
        if QREADY and targetMinion.health < getDmg("Q",targetMinion, myHero) then
          CustomDrawCircle(targetMinion.x,targetMinion.y,targetMinion.z, 150, drawKillMinionColor)
      end
      if targetMinion.health < getDmg("AD", targetMinion, myHero) then
        CustomDrawCircle(targetMinion.x,targetMinion.y,targetMinion.z, 100, drawKillMinionColor)
      end
      end
    end
  end
  if DCConfig.Drawing.wallJumps then
    for i = 1, #wallJumps do
      if GetDistance(wallJumps[i]) < (rangeMax * 2) then
        CustomDrawCircle(wallJumps[i].x,wallJumps[i].y,wallJumps[i].z, DCConfig.Misc.jumpMouseDistance, drawQColor)
      end
    end
  end
  for i = 1, heroManager.iCount do
    local enemydraw = heroManager:GetHero(i)
    if ValidTarget(enemydraw) then
      if DCConfig.Drawing.drawCirclesEnemy then
        if killable[i] == 1 then
          for j = 0, 20 do
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j * 1.5, drawQColor)
          end
        elseif killable[i] == 2 then
          for j = 0, 10 do
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j * 1.5, drawKillColor)
          end
        elseif killable[i] == 3 then
          for j = 0, 10 do
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j * 1.5, drawKillColor)
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 110 + j * 1.5, drawKillColor)
          end
        elseif killable[i] == 4 then
          for j = 0, 10 do
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 80 + j * 1.5, drawKillColor)
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 110 + j * 1.5, drawKillColor)
            CustomDrawCircle(enemydraw.x, enemydraw.y, enemydraw.z, 140 + j * 1.5, drawKillColor)
          end
        end
      end
      if DCConfig.Drawing.drawText and waittxt[i] == 1 and killable[i] ~= 0 then
        PrintFloatText(enemydraw, 0, floattext[killable[i]])
      end
    end
    if waittxt[i] == 1 then waittxt[i] = 30
    else waittxt[i] = waittxt[i] - 1
    end
  end
end

function CrescentCollision(mode)

  local targetOriginal = {}
  local targetArray = {}
  local tsTargetOriginal = {}
  local theta, tsTargetAngle, tsTarget, tsAngle, tsVo, tsTestZ
  local targetAngle, target, angle, vo, testZ
  local tsFlag = false
  highestCollision = 0
  highestAngle = 0
  highestRange = 0
  if mode == MODE_CHAMP then
    for i = 1, heroManager.iCount do
      local hero = heroManager:GetHero(i)
      if ValidTarget(hero, DCConfig.Misc.rangeMax) then
        local castPos = getQPrediction(hero)
        if castPos then
          table.insert(targetArray,castPos)
        end
      end
    end
    if ts.target and qPred and GetDistance(ts.target) < rangeMax then
      tsTargetOriginal = Vector(qPred.x - myHero.x, myHero.y, qPred.z - myHero.z)
      tsTargetAngle = tsTargetOriginal:polar()
    end
  elseif mode == MODE_MINION then
    targetArray = enemyMinions.objects
  end

  if #targetArray > 1 and QREADY then
    local rightTheta, leftTheta = GetBoundingVectors(targetArray)
    for newTheta = rightTheta, leftTheta, DCConfig.Performance.thetaIterator do --increase theta
      theta = math.rad(newTheta)

      for range = 400, DCConfig.Misc.rangeMax, DCConfig.Performance.rangeIterator do --increase range
        if highestCollision < #targetArray then
          local collisionCount = 0
          if mode == MODE_CHAMP and ts.target and qPred and GetDistance(ts.target) < rangeMax then --prioritize ts.target
            tsTargetOriginal = Vector(qPred.x - myHero.x, myHero.y, qPred.z - myHero.z)
            tsTarget = tsTargetOriginal:rotated(0, theta, 0)
            tsAngle = math.rad((-47) - (830 - range) / (-20)) --interpolate launch angle
            tsVo = math.sqrt((range * accel) / math.sin(2 * tsAngle)) -- initial velocity
            tsTestZ = math.tan(tsAngle) * tsTarget.x - (accel / (2 * tsVo ^ 2 * math.cos(tsAngle) ^ 2)) * tsTarget.x ^ 2
            if math.abs(math.ceil(tsTestZ) - math.ceil(qPred.z)) <= DCConfig.Performance.roundRange then
              tsFlag = true
              collisionCount = collisionCount + 1
            else
              tsFlag = false
            end
          end
          if mode == MODE_MINION or (tsFlag and mode == MODE_CHAMP) then --only search other champs if ts.target is a collision
            for index, minions in pairs(targetArray) do --iterate over minion/champ array
              if mode == MODE_MINION or minions.charName ~= ts.target.charName then
                targetOriginal = Vector(minions.x - myHero.x, myHero.y, minions.z - myHero.z)
                targetAngle = targetOriginal:polar()

                if (targetAngle <= newTheta) and ((mode ~= MODE_CHAMP) or (tsTargetAngle and tsTargetAngle <= newTheta)) then --angle of theta must be greater than target
                  target = targetOriginal:rotated(0, theta, 0) --rotate to neutral axis
                  angle = math.rad((-47) - (830 - range) / (-20)) --interpolate launch angle
                  vo = math.sqrt((range * accel) / math.sin(2 * angle)) -- initial velocity
                  testZ = math.tan(angle) * target.x - (accel / (2 * vo ^ 2 * math.cos(angle) ^ 2)) * target.x ^ 2

                  if math.abs(math.ceil(testZ) - math.ceil(target.z)) <= DCConfig.Performance.roundRange then --compensate for rounding
                    --collision detected
                    collisionCount = collisionCount + 1
                  end

                  if collisionCount > highestCollision then
                    highestCollision = collisionCount
                    highestAngle = theta --in radians
                    highestRange = range
                  end
                end
            end
          end
          end
      end
      end
    end
  end
end

function AutoIgnite()
  if IREADY and not QREADY then
    local ignitedmg = 0
    for i = 1, heroManager.iCount, 1 do
      local enemyhero = heroManager:getHero(i)
      if ValidTarget(enemyhero, 600) and GetDistance(enemyHero) > getMyTrueRange() then
        ignitedmg = 50 + 20 * myHero.level
        if enemyhero.health <= ignitedmg then
          CastSpell(ignite, enemyhero)
        end
      end
    end
  end
end

function getQPrediction(target)

  local castPos,hitChance,position


  if DCConfig.Prediction.predictionList == 1 then
    castPos = FreePredictionQ:GetPrediction(target)
  elseif DCConfig.Prediction.predictionList == 2 then
    castPos, hitChance, position = VP:GetLineCastPosition(target,qDelay,qWidth,DCConfig.Misc.rangeMax,qSpeed,myHero,false)
  elseif DCConfig.Prediction.predictionList == 3 and prodictionLoaded then
    castPos = ProdictionQ:GetPrediction(target)
  end
  if (hitChance and hitChance >= 2) or not hitchance then
    return castPos
  else
    return nil
  end
end

function ultKillSteal()

  for i = 1, heroManager.iCount, 1 do
    local enemyHero = heroManager:getHero(i)

    if ValidTarget(enemyHero, rRange) then

      local castPos = getQPrediction(enemyHero)

      if (QREADY and DCConfig.KillSteal.useQ) and (RREADY and DCConfig.KillSteal.useR) then --R and Q kill steal
        if castPos and GetDistance(castPos) < rangeMax then
          local totalDmg = getDmg("Q", enemyHero, myHero) + getDmg("R", enemyHero, myHero, 1) + getDmg("AD",enemyHero,myHero)
          if enemyHero.health <= totalDmg then
            UseSpell(_R,enemyHero)
            UseSpell(_Q,castPos.x, castPos.z)
          end
      end
      end
      if QREADY and DCConfig.KillSteal.useQ then   --Q kill steal
        if castPos then
          if enemyHero.health <= getDmg("Q", enemyHero, myHero) then
            UseSpell(_Q, castPos.x, castPos.z)
          end
      end
      if RREADY and DCConfig.KillSteal.useR then  --R kill steal
        if enemyHero.health <= (getDmg("R", enemyHero, myHero, 1) + getDmg("AD", enemyHero,myHero)) then
          UseSpell(_R, enemyHero)
      end
      end
      end
    end
  end
end

function ReadyCheck()
  BRKSlot, DFGSlot, HXGSlot, BWCSlot, TMTSlot, RAHSlot, RNDSlot, YGBSlot = GetInventorySlotItem(3153), GetInventorySlotItem(3128), GetInventorySlotItem(3146), GetInventorySlotItem(3144), GetInventorySlotItem(3077), GetInventorySlotItem(3074), GetInventorySlotItem(3143), GetInventorySlotItem(3142)
  QREADY = (myHero:CanUseSpell(_Q) == READY)
  WREADY = (myHero:CanUseSpell(_W) == READY)
  EREADY = (myHero:CanUseSpell(_E) == READY)
  RREADY = (myHero:CanUseSpell(_R) == READY)
  DFGREADY = (DFGSlot ~= nil and myHero:CanUseSpell(DFGSlot) == READY)
  HXGREADY = (HXGSlot ~= nil and myHero:CanUseSpell(HXGSlot) == READY)
  BWCREADY = (BWCSlot ~= nil and myHero:CanUseSpell(BWCSlot) == READY)
  BRKREADY = (BRKSlot ~= nil and myHero:CanUseSpell(BRKSlot) == READY)
  TMTREADY = (TMTSlot ~= nil and myHero:CanUseSpell(TMTSlot) == READY)
  RAHREADY = (RAHSlot ~= nil and myHero:CanUseSpell(RAHSlot) == READY)
  RNDREADY = (RNDSlot ~= nil and myHero:CanUseSpell(RNDSlot) == READY)
  YGBREADY = (YGBSlot ~= nil and myHero:CanUseSpell(YGBSlot) == READY)
  IREADY = (ignite ~= nil and myHero:CanUseSpell(ignite) == READY)
end

function UseItems(target)
  if GetDistance(target) < 550 then
    if DFGREADY then UseSpell(DFGSlot, target) end
    if HXGREADY then UseSpell(HXGSlot, target) end
    if BWCREADY then USeSpell(BWCSlot, target) end
    if BRKREADY then USeSpell(BRKSlot, target) end
    if YGBREADY then UseSpell(YGBSlot, target) end
    if TMTREADY and GetDistance(target) < 275 then UseSpell(TMTSlot) end
    if RAHREADY and GetDistance(target) < 275 then UseSpell(RAHSlot) end
    if RNDREADY and GetDistance(target) < 275 then UseSpell(RNDSlot) end
  end
end

function BurstCombo(target)

  if target and isEnemyInAttackRange(target) and DCConfig.NormalCombo.orbWalk then
    if timeToShoot() or shotFired == true then
      attackEnemy(target)
    else
      if heroCanMove() and DCConfig.NormalCombo.orbWalk then
        moveToTarget(target)
      end
    end
  elseif heroCanMove() and DCConfig.NormalCombo.orbWalk then
    if target then
      moveToTarget(target)
    else
      moveToMouse()
    end
  end

  if GetTickCount() - mainTimer < 49 then return end
  mainTimer = GetTickCount()

  if qPred ~= nil and QREADY and GetDistance(qPred) <= DCConfig.Misc.rangeMax then
    if (QREADY and RREADY) or (QREADY and not isEnemyInAttackRange(target)) or (QREADY and target.health < target.maxHealth * 0.3) then
      if highestCollision > 0 then
        UseSpell(_Q, myHero.x + highestRange * math.cos(highestAngle), myHero.z + highestRange * math.sin(highestAngle))
      else
        UseSpell(_Q, qPred.x, qPred.z)
      end
      myHero:Attack(target)
      if RREADY then
        QTick = GetTickCount()
      else
        QTick = nil
      end
      rtarget = target
    end
    myHero:Attack(target)
    QTick = GetTickCount()
    RDelay = (250 + (GetDistance(qPred) / 1.8))
  end
  if WREADY and GetDistance(target) <= wRange and DCConfig.NormalCombo.useW then
    UseSpell(_W)
  end
  if EREADY and GetDistance(target) > eBuffer and GetDistance(target) < eRange and DCConfig.NormalCombo.useE then
    UseSpell(_E)
  end
  if GetDistance(target) <= aaRange and DCConfig.NormalCombo.orbWalk == false then
    myHero:Attack(target)
  end

  if RREADY and rtarget and ValidTarget(rtarget, rRange) and QTick ~= nil then
    if GetTickCount() - QTick >= RDelay and MoonLight == false and GetTickCount() - QTick < 3000 - RDelay then
      UseSpell(_W)
      UseSpell(_R, rtarget)
      MoonLight = true
    end
  end
end

function Harass(target)
  if qPred and QREADY and GetDistance(qPred) <= DCConfig.Misc.rangeMax and DCConfig.Harassing.useQ then
    CrescentCollision(MODE_CHAMP)
    if highestCollision > 0 then
      UseSpell(_Q, myHero.x + highestRange * math.cos(highestAngle), myHero.z + highestRange * math.sin(highestAngle))
    else
      UseSpell(_Q, qPred.x, qPred.z)
    end
  end
  if WREAD and GetDistance(target) <= wRange and DCConfig.Harassing.useW then
    UseSpell(_W)
  end
  if DCConfig.Harassing.moveToMouse and not _G.evade then
    moveToMouse()
  end
end

function hasMoonLight(target)

  return TargetHaveBuff("dianamoonlight",target)

end

function OnCreateObj(Object)

  if isJungleMinion(Object) then
    table.insert(JungleMonsters, Object)
  end
  if Object and Object.name and Object.name:find("Diana_Q_moonlight_champ.troy") then
    for i = 1, heroManager.iCount do
      local enemy = heroManager:GetHero(i)
      if enemy.team ~= myHero.team and GetDistance(Object, enemy) < 50 then
        MoonLightEnemy[enemy.charName] = true
      end
    end
    for i = 1, #JungleMonsters do
      if GetDistance(Object,JungleMonsters[i]) < 50 then
        JungleMoonlight[Object.name] = true
      end
    end
  end

end

function OnProcessSpell(unit, spell)
  if unit.isMe and spell.name == "DianaArc" then MoonLight = false end
  if unit.isMe and (spell.name:find("Attack") ~= nil) then
    attackedSuccessfully()
  end
end

function OnDeleteObj(Object)
  if isJungleMinion(Object) then
    for i, obj in pairs(JungleMonsters) do
      if obj.name == Object.name then
        table.remove(JungleMonsters, i)
      end
    end
  end
  if Object and Object.name and Object.name:find("Diana_Q_moonlight_champ.troy") then
    for i = 1, heroManager.iCount do
      local enemy = heroManager:GetHero(i)
      if enemy.team ~= myHero.team and GetDistance(Object, enemy) < 50 then
        MoonLightEnemy[enemy.charName] = false
      end
    end
    for i = 1, #JungleMonsters, 1 do
      if GetDistance(Object,JungleMonsters[i]) < 50 then
        JungleMoonlight[Object.name] = false
      end
    end
  end
end

function DmgCalculation()
  local enemy = heroManager:GetHero(calculationenemy)
  if ValidTarget(enemy) then
    local ignitedamage, dfgdamage, hxgdamage, bwcdamage, brkdamage, tmtdamage, rahdamage = 0, 0, 0, 0, 0, 0, 0
    local pdamage = getDmg("P", enemy, myHero)
    local qdamage = getDmg("Q", enemy, myHero)
    local wdamage = getDmg("W", enemy, myHero)
    local rdamage = getDmg("R", enemy, myHero, 1)
    local hitdamage = getDmg("AD", enemy, myHero)
    local ignitedamage = (ignite and getDmg("IGNITE", enemy, myHero) or 0)
    local dfgdamage = (DFGSlot and getDmg("DFG", enemy, myHero) or 0)
    local hxgdamage = (HXGSlot and getDmg("HXG", enemy, myHero) or 0)
    local bwcdamage = (BWCSlot and getDmg("BWC", enemy, myHero) or 0)
    local brkdamage = (BRKSlot and getDmg("RUINEDKING", enemy, myHero) or 0)
    local tmtdamage = (TMTSlot and getDmg("TIAMAT", enemy, myHero) or 0)
    local rahdamage = (RAHSlot and getDmg("HYDRA", enemy, myHero) or 0)
    local combo1 = hitdamage * 2 + pdamage + qdamage + wdamage + (rdamage * 2)
    local combo2 = hitdamage * 2 + pdamage
    local combo3 = 0
    local combo4 = 0
    local combo5 = hitdamage * 2 + pdamage --full combo minus Q
    if QREADY then
      combo2 = combo2 + qdamage
      combo3 = combo3 + qdamage
      combo4 = combo4 + qdamage
    end
    if WREADY then
      combo2 = combo2 + wdamage
      combo3 = combo3 + wdamage
      combo5 = combo5 + wdamage
    end
    if RREADY then
      combo2 = combo2 + rdamage
      combo3 = combo3 + rdamage
      combo4 = combo4 + rdamage
      combo5 = combo5 + rdamage
    end
    if RREADY and QREADY then
      combo2 = combo2 + rdamage
      combo3 = combo3 + rdamage
      combo4 = combo4 + rdamage
      combo5 = combo5 + rdamage
    end
    if DFGREADY then
      combo1 = combo1 + dfgdamage
      combo2 = combo2 + dfgdamage
      combo3 = combo3 + dfgdamage
      combo5 = combo5 + dfgdamage
    end
    if HXGREADY then
      combo1 = combo1 + hxgdamage
      combo2 = combo2 + hxgdamage
      combo3 = combo3 + hxgdamage
      combo5 = combo5 + hxgdamage
    end
    if BWCREADY then
      combo1 = combo1 + bwcdamage
      combo2 = combo2 + bwcdamage
      combo3 = combo3 + bwcdamage
      combo5 = combo5 + bwcdamage
    end
    if BRKREADY then
      combo1 = combo1 + brkdamage
      combo2 = combo2 + brkdamage
      combo3 = combo3 + brkdamage
      combo5 = combo5 + brkdamage
    end
    if TMTREADY then
      combo1 = combo1 + tmtdamage
      combo2 = combo2 + tmtdamage
      combo3 = combo3 + tmtdamage
      combo5 = combo5 + tmtdamage
    end
    if RAHREADY then
      combo1 = combo1 + rahdamage
      combo2 = combo2 + rahdamage
      combo3 = combo3 + rahdamage
      combo5 = combo5 + rahdamage
    end
    if IREADY then
      combo1 = combo1 + ignitedamage
      combo2 = combo2 + ignitedamage
      combo3 = combo3 + ignitedamage
      combo5 = combo5 + ignitedamage
    end
    if combo4 >= enemy.health then killable[calculationenemy] = 4 -- Q + R ready only
    elseif combo3 >= enemy.health then killable[calculationenemy] = 3 --all items,ready skills,Rx2
    elseif combo2 >= enemy.health then killable[calculationenemy] = 2 --all items,ready skills Rx2, AD
    elseif combo1 >= enemy.health then killable[calculationenemy] = 1 --all items, AD, not ready skills Rx2
    else killable[calculationenemy] = 0
    end
  end
  if calculationenemy == 1 then calculationenemy = heroManager.iCount
  else calculationenemy = calculationenemy - 1
  end
end

function areClockwise(testv1, testv2)
  return -testv1.x * testv2.z + testv1.z * testv2.x > 0 --true if v1 is clockwise to v2
end

function GetBoundingVectors(coneTargetsTable)

  --Build table of enemies in range
  local n = 1
  local v1, v2, v3 = 0, 0, 0
  local largeN, largeV1, largeV2 = 0, 0, 0
  local theta1, theta2 = 0, 0

  if #coneTargetsTable >= 2 then -- true if calculation is needed
    for i = 1, #coneTargetsTable, 1 do
      for j = 1, #coneTargetsTable, 1 do
        if i ~= j then
          --Position vector from player to 2 different targets.
          v1 = Vector(coneTargetsTable[i].x - myHero.x, myHero.y, coneTargetsTable[i].z - myHero.z)
          v2 = Vector(coneTargetsTable[j].x - myHero.x, myHero.y, coneTargetsTable[j].z - myHero.z)

          if #coneTargetsTable == 2 then --only 2 targets, the result is found.
            largeV1 = v1
            largeV2 = v2
          else
            --Determine # of vectors between v1 and v2
            local tempN = 0
            for k = 1, #coneTargetsTable, 1 do
              if k ~= i and k ~= j then
                --Build position vector of third target
                v3 = Vector(coneTargetsTable[k].x - myHero.x, myHero.y, coneTargetsTable[k].z - myHero.z)
                --For v3 to be between v1 and v2
                --it must be clockwise to v1
                --and counter-clockwise to v2
                if areClockwise(v3, v1) and not areClockwise(v3, v2) then
                  tempN = tempN + 1
                end
              end
            end
            if tempN > largeN then
              --store the largest number of contained enemies
              --and the bounding position vectors
              largeN = tempN
              largeV1 = v1
              largeV2 = v2
            end
          end
        end
      end
  end
  end

  theta1 = largeV1:polar() - 20
  theta2 = largeV2:polar() + 20
  if theta2 < theta1 then
    theta1 = theta1 - 360
  end
  return theta1, theta2
end
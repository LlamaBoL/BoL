--[[ LoL Measurement tool.
                by llama
--]]
 
function OnLoad()
       
        addThetaHK = string.byte("X")
        subThetaHK = string.byte("Z")
        addRHK = string.byte("S")
        subRHK = string.byte("A")
        defaultTheta = 45 --degrees
        thetaMax = 360
        thetaInterval = 1
        thetaMin = 0
        radiusInterval = 5
        defaultRadius = 600
        radiusMax = 2000
        v1 = {}
        v2 = {}
        MeasureAngle = scriptConfig("Skill Measurement","measureTheta")
       
        MeasureAngle:addParam("theta","Theta Value",SCRIPT_PARAM_SLICE,defaultTheta,thetaMin,thetaMax,0)
        MeasureAngle:addParam("radius","Radius Value",SCRIPT_PARAM_SLICE,defaultRadius,0,radiusMax,0)
        MeasureAngle:addParam("addTheta","theta+1",SCRIPT_PARAM_ONKEYDOWN, false, addThetaHK)
        MeasureAngle:addParam("subTheta","theta-1",SCRIPT_PARAM_ONKEYDOWN, false, subThetaHK)
        MeasureAngle:addParam("addR","radius+5",SCRIPT_PARAM_ONKEYDOWN, false, addRHK)
        MeasureAngle:addParam("subR","radius-5",SCRIPT_PARAM_ONKEYDOWN, false, subRHK)
        MeasureAngle:permaShow("theta")
        MeasureAngle:permaShow("radius")
        PrintChat("Loaded!")
end
 
function OnDraw()
 
        upperTheta = math.rad(MeasureAngle.theta/2)
        lowerTheta = math.rad(-MeasureAngle.theta/2)
       
        v1.x = MeasureAngle.radius*math.cos(upperTheta)+player.x
        v1.y = player.y
        v1.z = MeasureAngle.radius*math.sin(upperTheta)+player.z
       
        v2.x = MeasureAngle.radius*math.cos(lowerTheta)+player.x
        v2.y = player.y
        v2.z = MeasureAngle.radius*math.sin(lowerTheta)+player.z
 
        DrawArrows(player,v1,30,0xFFFFFF)
        DrawArrows(player,v2,30,0xFFFFFF)
        DrawCircle(player.x,player.y,player.z,MeasureAngle.radius,0xFFFFFF)
end
 
function OnTick()
 
        if MeasureAngle.addTheta then  
                if MeasureAngle.theta == thetaMax then
                        MeasureAngle.theta = thetaMin
                else
                        MeasureAngle.theta = MeasureAngle.theta+thetaInterval
                end
                MeasureAngle.addTheta = false
        end
        if MeasureAngle.subTheta then
                if MeasureAngle.theta == thetaMin then
                        MeasureAngle.theta = thetaMax
                else
                        MeasureAngle.theta = MeasureAngle.theta-thetaInterval
                end
                MeasureAngle.subTheta = false
        end
        if MeasureAngle.addR then              
                if MeasureAngle.radius == radiusMax then
                        MeasureAngle.radius = 0
                else
                        MeasureAngle.radius = MeasureAngle.radius+radiusInterval
                end
                MeasureAngle.addR = false
        end
        if MeasureAngle.subR then
                if MeasureAngle.radius == 0 then
                        MeasureAngle.radius = radiusMax
                else
                        MeasureAngle.radius = MeasureAngle.radius-radiusInterval
                end
                        MeasureAngle.subR = false
        end
end
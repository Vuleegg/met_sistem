ESX = exports['es_extended']:getSharedObject()
exports('AddBoxZone', AddBoxZone)
local RNE = RegisterNetEvent
local TE = TriggerEvent
local AEH = AddEventHandler 
local TSE = TriggerServerEvent
local burad = {}
local spawnedBurad = 0
local BuradPlants = {}
local isPickingUp, isProcessing = false, false



local function AddPolyZone(name, points, options, targetoptions)
	local _points = {}
	if type(points[1]) == 'table' then
		for i = 1, #points do
			_points[i] = vec2(points[i].x, points[i].y)
		end
	end
	Zones[name] = PolyZone:Create(#_points > 0 and _points or points, options)
	targetoptions.distance = targetoptions.distance or Config.MaxDistance
	Zones[name].targetoptions = targetoptions
	return Zones[name]
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		local coords = GetEntityCoords(PlayerPedId())

		if GetDistanceBetweenCoords(coords, Config.Search.methsearch.coords, true) < 50 then
			SpawnBuradPlants()
			Citizen.Wait(500)
		else
			Citizen.Wait(500)
		end
	end
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		for k, v in pairs(BuradPlants) do
			ESX.Game.DeleteObject(v)
		end
	end
end)

function SpawnBuradPlants()
	while spawnedBurad < 15 do
		Citizen.Wait(0)
		local bureCoords = GenerateCocaLeafCoords()

		ESX.Game.SpawnLocalObject('prop_barrel_01a', bureCoords, function(obj)
			PlaceObjectOnGroundProperly(obj)
			FreezeEntityPosition(obj, true)

			table.insert(BuradPlants, obj)
			spawnedBurad = spawnedBurad + 1
		end)
	end
end

function ValidateCocaLeafCoord(plantCoord)
	if spawnedBurad > 0 then
		local validate = true

		for k, v in pairs(BuradPlants) do
			if GetDistanceBetweenCoords(plantCoord, GetEntityCoords(v), true) < 5 then
				validate = false
			end
		end

		if GetDistanceBetweenCoords(plantCoord, Config.Search.methsearch.coords, false) > 50 then
			validate = false
		end

		return validate
	else
		return true
	end
end

function GenerateCocaLeafCoords()
	while true do
		Citizen.Wait(1)

		local bureCoordX, bureCoordY

		math.randomseed(GetGameTimer())
		local modX = math.random(-20, 20)

		Citizen.Wait(100)

		math.randomseed(GetGameTimer())
		local modY = math.random(-20, 20)

		bureCoordX = Config.Search.methsearch.coords.x + modX
		bureCoordY = Config.Search.methsearch.coords.y + modY

		local coordZ = GetCoordZBurad(bureCoordX, bureCoordY)
		local coord = vector3(bureCoordX, bureCoordY, coordZ)

		if ValidateCocaLeafCoord(coord) then
			return coord
		end
	end
end

function GetCoordZBurad(x, y)
	local groundCheckHeights = { 70.0, 71.0, 72.0, 73.0, 74.0, 75.0, 76.0, 77.0, 78.0, 79.0, 80.0 }

	for i, height in ipairs(groundCheckHeights) do
		local foundGround, z = GetGroundZFor_3dCoord(x, y, height)

		if foundGround then
			return z
		end
	end

	return 77
end


function OpenPlant()
    TaskStartScenarioInPlace(PlayerPedId(), "WORLD_HUMAN_GARDENER_PLANT", 0, true)
    Citizen.Wait(10000)
    ESX.Game.DeleteObject(nearbyObject)
    TriggerServerEvent('vule:dajitem')
    ClearPedTasksImmediately(PlayerPedId())
end

local function GetBuradLabel(name)
    for _, burad in pairs(Config.Barrel) do
        if burad.zone.name == name then return burad.label end
    end
end 
Citizen.CreateThread(function()
    for k, v in pairs(Config.Barrel) do

        burad[k] = BoxZone:Create(
            vector3(v.zone.x, v.zone.y, v.zone.z),
            v.zone.l, v.zone.w, {
                name = v.zone.name,
                heading = v.zone.h,
                debugPoly = false,
                minZ = v.zone.minZ,
                maxZ = v.zone.maxZ
            }
        )
		burad[k].type = v.type
        burad[k].label = v.label
    end
end)
function IsInsideZone(type, entity)
    local entityCoords = GetEntityCoords(entity)

	for k, v in pairs(burad) do
		if burad[k]:isPointInside(entityCoords) then
			currentburad = Config.Barrel[k]
			return true
		end
		if k == #burad then return false end
	end
    
end


Citizen.CreateThread(function()
	exports.qtarget:AddTargetModel({-1738103333}, {
		options = {
			{
				event = "meth:search",
				icon = "fa-solid fa-bucket",
				label = "Pretrazi bure",
				canInteract = function(entity)
					hasChecked = false
					if IsInsideZone('burad', entity) and not hasChecked then
						hasChecked = true
						return true
					end
				end
			},
		},
		distance = 2
	})
end)




RNE("meth:search", function()
	
	local playerPed = PlayerPedId()
	local coords = GetEntityCoords(playerPed)
	local nearbyObject, nearbyID

	for i=1, #BuradPlants, 1 do
		if GetDistanceBetweenCoords(coords, GetEntityCoords(BuradPlants[i]), false) < 1 then
			nearbyObject, nearbyID = BuradPlants[i], i
		end
	end
	if nearbyObject and IsPedOnFoot(playerPed) then
	
		TaskStartScenarioInPlace(playerPed, 'PROP_HUMAN_BUM_BIN', 0, false)

		Citizen.Wait(2000)
		ClearPedTasks(playerPed)
		Citizen.Wait(1500)

		ESX.Game.DeleteObject(nearbyObject)

		table.remove(BuradPlants, nearbyID)
		spawnedBurad = spawnedBurad - 1

		TriggerServerEvent('meth:bure')
	end


end)



RNE("methcook", function()
	ESX.TriggerServerCallback('meth:system',function(check)
	if check then
		lib.progressCircle({
			duration = 30000,
			useWhileDead = false,
			canCancel = false,
			disable = {
				move = true,
				car = true,
				combat = true,
			},
		anim = { dict = 'anim@amb@clubhouse@tutorial@bkr_tut_ig3@', clip = 'machinic_loop_mechandplayer' },
	}) 
else
	ESX.ShowNotification("Nesto vam fali!!!")
end
end) 
end)


RNE("abillity", function()
	lib.progressCircle({
		duration = 30000,
		useWhileDead = false,
		canCancel = false,
		disable = {
			move = true,
			car = true,
			combat = true,
		},
        anim = {
            dict =  'mp_player_inteat@burger',
            clip = 'mp_player_int_eat_burger_fp' ,
        },
        prop = { model = 'prop_meth_bag_01', pos = { x = 0.020000000000004, y = 0.020000000000004, y = -0.020000000000004}, rot = { x = 0.0, y = 0.0, y = 0.0} },
    })
    Wait(500)
SetPedMotionBlur(PlayerPedId(), true)
AddArmourToPed(PlayerPedId(), 50)
SetEntityHealth(PlayerPedId(), GetEntityHealth(PlayerPedId()) + 100)
Wait(500)
ESX.ShowNotification("Iskoristili ste met")
end)



exports.qtarget:AddBoxZone("kuvanjemeta", vector3(3559.503, 3673.973, 29.367), 0.45, 0.35, {
	name="kuvanjemeta",
	heading=11.0,
	debugPoly=false,
	minZ=28.367,
	maxZ=30.367,
	}, {
		options = {
			{
				event = "methcook",
				label = "Kuvajte met",
			},
		},
		distance = 6.5
})

exports.qtarget:AddBoxZone("processing", vector3(1391.846, 3605.776, 38.941), 1.85, 1.85, { 
	name="processing",
	heading=11.0,
	debugPoly=false,
	minZ=37.941,
	maxZ=39.941,
	}, {
		options = {
			{
				event = "process_cl",
				icon = "fas fa-sign-in-alt",
				label = "Preradite met",
			},
		},
		distance = 3.5
})

exports.qtarget:AddBoxZone("sell", vector3(1402.408, 3600.346, 35.021), 1.85, 1.85, { 
	name="sell",
	heading=11.0,
	debugPoly=false,
	minZ=34.021,
	maxZ=36.021,
	}, {
		options = {
			{
				event = "sell_cl",
				icon = "fas fa-sign-in-alt",
				label = "Prodajte met",
			},
		},
		distance = 3.5
})

RNE("sell_cl", function()
ESX.TriggerServerCallback("sell",function(check3)
	if check3 then
	else
		ESX.ShowNotification("Nemate dovoljno cistog meta!")
	end
	end)
end)	

RNE("process_cl", function()
	ESX.TriggerServerCallback("processing",function(check2)
	if check2 then
	else
		ESX.ShowNotification("Nesto vam fali!!!")
	end
	end)
end)	

Citizen.CreateThread(function()
	
	RequestModel(GetHashKey('a_m_m_og_boss_01'))
	while not HasModelLoaded(GetHashKey('a_m_m_og_boss_01')) do
	Wait(1)
	end
	
	PostaviPeda = CreatePed(4, 'a_m_m_og_boss_01', vector3(1401.367, 3599.902, 34.035) , 120.0, false, true)
	FreezeEntityPosition(PostaviPeda, true) 
	SetEntityInvincible(PostaviPeda, true)
	SetBlockingOfNonTemporaryEvents(PostaviPeda, true)
end)


CreateThread(function()
	while true do
		Wait(0)
		local igrac = PlayerPedId()
		local kordinate = GetEntityCoords(igrac)
		local distanca = #(kordinate - vector3(1401.367, 3599.902, 34.035))
		local spavaj = true
		if distanca < 30 then
			spavaj = false
			Draw3DText(1401.367, 3599.902, 34.0357 - 1.15, "[Prodaja meta] [Pritisnite ALT]", 7, 0.1, 0.1)
		end
		if spavaj then Wait(1337) end
	end
  end)
  
  
  function Draw3DText(x, y, z, textInput, fontId, scaleX, scaleY)
	local px, py, pz = table.unpack(GetGameplayCamCoords())
	local dist = GetDistanceBetweenCoords(px, py, pz, x, y, z, 1)
	local scale = (1 / dist) * 20
	local fov = (1 / GetGameplayCamFov()) * 100
	local scale = scale * fov
	SetTextScale(scaleX * scale, scaleY * scale)
	SetTextFont(fontId)
	SetTextProportional(1)
	SetTextColour(94, 102, 198, 0.8) 
	SetTextDropshadow(1, 1, 1, 1, 255)
	SetTextEdge(2, 0, 0, 0, 150)
	SetTextDropShadow()
	SetTextOutline()
	SetTextEntry("STRING")
	SetTextCentre(1)
	AddTextComponentString(textInput)
	SetDrawOrigin(x, y, z + 2, 0)
	DrawText(0.0, 0.0)
	ClearDrawOrigin()
  end 


Citizen.CreateThread(function()
    blip = AddBlipForCoord(vector3(3559.503, 3673.973, 29.367))
    SetBlipSprite(blip, 140)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 5)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Kuvanje meta")
    EndTextCommandSetBlipName(blip)
end)   

Citizen.CreateThread(function()
    blip = AddBlipForCoord(vector3(1173.183, -2939.41, 5.9021))
    SetBlipSprite(blip, 436)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Burici met-a")
    EndTextCommandSetBlipName(blip)
end)   

Citizen.CreateThread(function()
    blip = AddBlipForCoord(vector3(1391.846, 3605.776, 38.941))
    SetBlipSprite(blip, 267)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Prerada meta")
    EndTextCommandSetBlipName(blip)
end)   


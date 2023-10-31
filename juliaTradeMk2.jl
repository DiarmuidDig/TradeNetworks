# Traders can now plot and follow a course from any given start to any given finish town!
# Time to get some trading going!

# I went off in all the python notebooks in the folder to figure out some population dynamics
# that I thin kwork well. There are problem swith the versions I have but I have interacting
# populaltion, production, and consumption rates, and support for multiple types of products
# and the resulting surpluses. I like it. There are also a good few simplifications built in
# with no storage (because I thik nthat'll be a cultural thing), no amount of production for
# for trade apart from a surplus above the carrying capacity (see voicenote yesterday, 27/8/23)
# for more details), but it works. Goal now is to add this system to each town here, then add
# the traders to move the surplus around.

# Track the imprecision error all the back and fix it at the root
# Decide on trader behaviour

# Break all the messy functions I have here up into separate packages I can call as needed, clean tehm up while transferring htem, maybe nail down design and functionalities while i'm at it

using Random
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

include("Astar.jl")
include("WorldGen.jl")

# General system config
mapWidth= 500
mapHeight = 300
townNum = 14
traderNum = 1
numAssets = 1

# Population dynamics variables
rN = 0.01
maxrP = 0.3
delayLength = 10

maxInitPopulation = 400.0
maxProdRatePerPerson = 10.0
maxAbsoluteProdRate = 500.0
maxInitMoney = 100.0
maxConPerPerson = 5.0


#------------------------------------------------------------------------------------------
#--------------------------------- Town Behaviour -----------------------------------------
#------------------------------------------------------------------------------------------

function recordTownProperties(town)
    push!(town["Nhistory"], town["population"])
    return town
end

# I think the code is running! For population updates it gives a newN value with no errors, the only
# problem is the weirdness of the values it gives. Have a look at balance and we should be flying!

# Carrying capacity functions
function kN(Plist, Clist)
    #println("Plist = " * string(Plist))
    #println("Clist = " * string(Clist))
    #println("kN list = " * string(minimum(Plist ./ Clist)))
    return minimum(Plist ./ Clist)
end
function kP(N, P, maxP)
    return min(P, maxP) * N
end

# Change in population and prod rate in one time increment
function dPdt(town, asset)
    #println("town = " * town)
    #println("p history = " * town["Phistory"])
    currentP = last(town["Phistory"])[asset]
    delayedP = town["Phistory"][reverseind(town["Phistory"], delayLength)][asset]
    N = last(town["Nhistory"])
    
    #println("currentP = " * string(currentP))
    #println("delayedP = " * string(delayedP))

    return town["rP"][asset] * currentP * (1-(delayedP/kP(N, currentP, town["maxProdRatesPerPerson"][asset])))
end
function dNdt(town)
    
    Plength = length(town["Phistory"])
    #println("Plength = " * string(Plength))
    #println("Pwidth = " * string(Pwidth))

    #println("test print = " * string(town["Phistory"][Plength]))
    #println("delayedN/kN = " * string((town["Nhistory"][reverseind(town["Nhistory"], delayLength)]/kN(last(town["Nhistory"]) * town["Phistory"][Plength], town["conRates"]))))
    return rN * last(town["Nhistory"]) * (1 - (town["Nhistory"][reverseind(town["Nhistory"], delayLength)]/kN(last(town["Nhistory"])*town["Phistory"][Plength], town["conRates"])))
end

# Next steps: double check the implementation of the derivatives above, integrate into the update functions below, set the whole system running and sort any bugs
function updateTownPopulation(town)
    #println("nhistory = " * string(town["Nhistory"]))
    #println("Phistory = " * string(town["Phistory"]))

    Nincrement = dNdt(town)
    newN = last(town["Nhistory"]) + Nincrement

    #println("newN = " * string(newN))
    #println("N = " * string(last(town["Nhistory"])))
    #println("Nincrement = " * string(Nincrement))
    #println("town = " * string(town))
    push!(town["Nhistory"], newN)
    return town
end

# need to figure out the push system here
function updateTownRates(town)
    pIncrementList = [0.0 for i in range(1, numAssets)]
    for asset in range(1, numAssets)
        pIncrementList[asset] = dPdt(town, asset)
    end
    newPList = last(town["Phistory"]) .+ pIncrementList
    #println("oldPList = " * string(last(town["Phistory"])))
    #println("pIncrement = " * string(pIncrementList))
    #println("newPList = " * string(newPList))
    push!(town["Phistory"], newPList)
    #println("pIncrementList = " * string(pIncrementList))


    return town
end


function townTick(townList)
    for town in townList
        #town = recordTownProperties(town)
        town = updateTownPopulation(town)
        town = updateTownRates(town)
    end
    return townList
end

#------------------------------------------------------------------------------------------
#----------------------------------- Trader Stuff -----------------------------------------
#------------------------------------------------------------------------------------------

function instantiateTraders(townList, traderNum)
    traderList = []
    for i in range(1,traderNum)
        townIndex = rand(range(1, length(townList)))

        trader = Dict("x" => townList[townIndex]["x"],
                      "y" => townList[townIndex]["y"],
                      "state" => "finalTown",
                      "currentTown" => townIndex,
                      "immediateTarget" => 1,
                      "finalTarget" => 2,
                      "finalTargetHistory" => [],
                      "immediateTargetHistory" => [],
                      "path" => [],
                      "currentVector" => [],
                      "xPositionHistory" => [],
                      "yPositionHistory" => [],
                      "speed" => rand(range(1.5,3,100)))

        trader["currentVector"] = [townList[trader["immediateTarget"]]["x"] - townList[townIndex]["x"], 
                                   townList[trader["immediateTarget"]]["y"] - townList[townIndex]["y"]]
                                   
        push!(traderList, trader)
    end
    return traderList
end    

# Move trader position speed increments along the vector to its immediate target
function moveTrader(trader)
    push!(trader["xPositionHistory"], trader["x"])
    push!(trader["yPositionHistory"], trader["y"])

    trader["x"] += trader["speed"] * trader["currentVector"][1]
    trader["y"] += trader["speed"] * trader["currentVector"][2]

    return trader
end

# Precalculate the vector from teh current position (a town) to their immediate target (the next town they're heading for)
function setTraderVector(trader, townList)
    trader["currentVector"] = [townList[trader["immediateTarget"]]["x"] - townList[trader["currentTown"]]["x"], 
                               townList[trader["immediateTarget"]]["y"] - townList[trader["currentTown"]]["y"]]
    
    # Comment these two lines for unnormalised vector, you'll also prob need to adjust the speed in moveTrader()
    normalisationConst = sqrt(trader["currentVector"][1]^2 + trader["currentVector"][2]^2)
    trader["currentVector"] = [trader["currentVector"][1]/normalisationConst, trader["currentVector"][2]/normalisationConst]
    
    return trader
end

# As it is now, pick a random town in townList, if it's not the current town set it as final target
# Calculate the path between current and target town and set first in that path as immediate target
function pickTraderTarget(trader, links, townList)
    proposedTown = rand(range(1,length(townList)))
    if proposedTown != trader["currentTown"]
    
        trader["finalTarget"] = proposedTown
        
        trader["path"] = findPathBetweenTwoTowns(trader["currentTown"], proposedTown, links, townList)
        trader["immediateTarget"] = trader["path"][1]
    end

    trader = setTraderVector(trader, townList)
    return trader
end

# Run one tick of the trader behaviour
function tradersTick(traderList, links, townList)
    #println(traderList[1])
    for trader in traderList
        push!(trader["finalTargetHistory"], trader["finalTarget"])
        push!(trader["immediateTargetHistory"], trader["immediateTarget"])

        if trader["state"] == "finalTown"
            trader = pickTraderTarget(trader, links, townList)
            trader["state"] = "travelling"

            push!(trader["xPositionHistory"], trader["x"])
            push!(trader["yPositionHistory"], trader["y"])

        elseif trader["state"] == "routeTown"
            popfirst!(trader["path"])
            trader["immediateTarget"] = trader["path"][1]
            setTraderVector(trader, townList)

            trader["state"] = "travelling"

            push!(trader["xPositionHistory"], trader["x"])
            push!(trader["yPositionHistory"], trader["y"])

        elseif trader["state"] == "travelling"
            if (trader["x"] - townList[trader["immediateTarget"]]["x"])^2 + (trader["y"] - townList[trader["immediateTarget"]]["y"])^2 < 10
                # Set trader to the town it collided with
                trader["state"] = "routeTown"
                trader["currentTown"] = trader["immediateTarget"]
                trader["x"] = townList[trader["currentTown"]]["x"]
                trader["y"] = townList[trader["currentTown"]]["y"]

                push!(trader["xPositionHistory"], trader["x"])
                push!(trader["yPositionHistory"], trader["y"])

                if trader["currentTown"] == trader["finalTarget"]
                    trader["state"] = "finalTown"
                else
                    trader["state"] = "routeTown"
                end
            else
                trader = moveTrader(trader)
            end
        end
    end
    return traderList
end



#------------------------------------------------------------------------------------------
#--------------------------------------- Run Code -----------------------------------------
#------------------------------------------------------------------------------------------

townList, links, distanceMatrix, pathDistances = generateWorldMapNetwork(townNum, mapWidth, mapHeight)
traderList = instantiateTraders(townList, traderNum)



# Have a look at the variables here, I thought I was being very functional with my design patterns but I think
# I'm missing something about how Julia handles parameters and scope because nothing is being returned here so
# the fact that it's still changing the outcome means something is being mutated
animFrameCount = 400
println(townList[1])
for i in range(1,animFrameCount)
    #tradersTick(traderList, links, townList)
    townTick(townList)
    #println(traderList[1]["state"])
end

#println("townlen = " * string(length(townList[1]{"Nhistory"})))
#plot(range(1,animFrameCount+delayLength), townList[1]["Nhistory"])
#plot(range(1,animFrameCount+delayLength), townList[1]["Nhistory"] .* townList[1]["Phistory"][1])
#gui()
#readline()

# I think we might need to refactor this. Switch it to store a list of
# coordinates at each timestep, that'll show the overall progression over time while just having one x and
# one y to deal with, that can be plugged straight in to show the whole system without looping though traders
#= anim = @animate for i = 1:animFrameCount
    #drawNetwork(townList, links, traderList)
    scatter!(range(1,animFrameCount), [townList[1]["populationHistory"][i]])
    #scatter!([townList[traderList[1]["finalTargetHistory"][i]]["x"]], [townList[traderList[1]["finalTargetHistory"][i]]["y"]], color="orange")
    #for trader in traderList
    #    scatter!((trader["xPositionHistory"][i], trader["yPositionHistory"][i]), color="red")
    #end
end 
gif(anim, "testAnimation.gif", fps=50) =#
drawNetwork(townList, links, traderList)
gui()
readline()
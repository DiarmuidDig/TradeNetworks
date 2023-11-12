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


using Random
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

include("Astar.jl")
include("WorldGen.jl")
include("TraderManager.jl")
include("GraphicsStuff.jl")

# General system config
mapWidth= 500
mapHeight = 300
townNum = 2
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
#--------------------------------------- Run Code -----------------------------------------
#------------------------------------------------------------------------------------------

townList, links, distanceMatrix, pathDistances = generateWorldMapNetwork(townNum, mapWidth, mapHeight)
traderList = instantiateTraders(townList, traderNum)



# Have a look at the variables here, I thought I was being very functional with my design patterns but I think
# I'm missing something about how Julia handles parameters and scope because nothing is being returned here so
# the fact that it's still changing the outcome means something is being mutated

function runSimulation(duration)
    for i in range(1,duration)
        tradersTick(traderList, links, townList)
        townTick(townList)
    end
end

animFrameCount = 500
runSimulation(animFrameCount)

drawTownHistory(townList)

#generateAnimationGif(townList, links, traderList)

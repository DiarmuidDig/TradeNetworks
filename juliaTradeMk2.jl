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



# End of day wrap-up:
#= Storage object almost up and running, just integrate it into the recording
functions, then plotting, and remove all history stuff from the towns themselves, then
we're good to go and get back to work on the main stuff! (which is the town update maths and
then trader behaviour, with general performance chekcs and imprrovements when I can). It's also
very worth adding all this to the docs at some stage (the world gen stack has been updated with
the generate storage object step, how the storage object works, all that stuff) =#

#= Actually I'd like to come up with a storage system for the trader histories as well. Storing
it all on the trader isn't as bad as the town since for now the trader objects aren't really
passed around at all but it could get to the point that it would be faster to store them separately
once trade starts kicking in. It could also just be more organised to have all the storage in one
place. If I do this, do more or less the same as with the town storage and move them all to one
script (the trader storage objects will probably be a bit more complicated than the town ones).
I don't think it needs to be done now but I would like to do it eventually. =#

#= Also fyi I don't have a clue hwat's causing that array must be nonempty error. I'll have a
better idea once I start passing the tick count around and I can see when it happens, if it's on
the first frame I might have a few ideas for what it could be. =#

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
townNum = 4
traderNum = 1
numAssets = 2 # Can't be zero
simDuration = 3


# Population dynamics variables
rN = 0.01
maxrP = 0.3
delayLength = 8

maxInitPopulation = 400.0
maxProdRatePerPerson = 10.0
maxAbsoluteProdRate = 500.0
maxInitMoney = 100.0
maxConPerPerson = 5.0


#------------------------------------------------------------------------------------------
#--------------------------------- Town Behaviour -----------------------------------------
#------------------------------------------------------------------------------------------

# I think the code is running! For population updates it gives a newN value with no errors, the only
# problem is the weirdness of the values it gives. Have a look at balance and we should be flying!

# Carrying capacity functions
function kN(Plist, Clist)
    return minimum(Plist ./ Clist)
end
function kP(N, P, maxP)
    return min(P, maxP) * N
end

# Change in population and prod rate in one time increment
function dPdt(town, asset)
    # Done in discrete variables as a holdover from a previous version that I don't feel like changing
    currentP = town["prodRates"][asset]
    delayedP = town["populationDelay"][asset]
    N = town["population"]
    return town["rP"][asset] * currentP * (1-(delayedP/kP(N, currentP, town["maxProdRatesPerPerson"][asset])))
end
function dNdt(town)
    return rN * town["population"] * (1 - town["populationDelay"][1]) / kN(town["population"]*town["prodRates"], town["conRates"])
end

function updateTownPopulation(town)
    # Split up over a few lines here for testing
    Nincrement = dNdt(town)
    newN = town["population"] + Nincrement
    town["population"] = newN

    push!(town["populationDelay"], town["population"])
    popfirst!(town["populationDelay"])

    return town
end

function updateTownRates(town)
    pIncrementList = [0.0 for i in range(1, numAssets)]
    for asset in range(1, numAssets)
        pIncrementList[asset] = dPdt(town, asset)
    end
    newPList = town["prodRates"] .+ pIncrementList
    town["prodRates"] = newPList

    push!(town["prodRatesDelay"], town["prodRates"])
    popfirst!(town["prodRatesDelay"])

    return town
end

function recordTownHistory(town, townIndex, currentTick)
    # Record the population in the global storage object
    townHistories[townIndex][1][currentTick] = town["population"]
    # Set the whole column for the current tick's rates at once, less flexible but saves looping over them all
    townHistories[townIndex][2][:,currentTick] = town["prodRates"]

    return townHistories
end 


function townTick(townList, currentTick)
    for i in range(1, length(townList))
        #town = recordTownProperties(town)
        town = updateTownPopulation(townList[i])
        town = updateTownRates(townList[i])

        townHistories = recordTownHistory(townList[i], i, currentTick)
    end
    return townList
end


#------------------------------------------------------------------------------------------
#--------------------------------------- Run Code -----------------------------------------
#------------------------------------------------------------------------------------------

townList, links, distanceMatrix, townHistories = generateWorldMapNetwork(townNum, mapWidth, mapHeight, simDuration)
traderList = instantiateTraders(townList, traderNum)


print(townHistories)
# Have a look at the variables here, I thought I was being very functional with my design patterns but I think
# I'm missing something about how Julia handles parameters and scope because nothing is being returned here so
# the fact that it's still changing the outcome means something is being mutated

function runSimulation(duration)
    for i in range(delayLength,duration+delayLength)
        tradersTick(traderList, links, townList)
        townTick(townList, i)
        println(townList[1]["populationDelay"])
    end
end

runSimulation(simDuration)
println(townHistories)
#drawTownHistory(townList)

#generateAnimationGif(townList, links, traderList)

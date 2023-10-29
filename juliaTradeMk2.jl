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
#------------------------------------------ A* --------------------------------------------
#------------------------------------------------------------------------------------------

#= Can add an extra cost (or reduce cost) for each city if you want to tailor the behaviour
   Just add or remove a cost in this. Since this is run for each town that'll incentivise
   paths through more or less towns depending =#
function heuristicCost(proposedNextPoint, finish, townList)
    return floor(Int, 1.2*(townList[finish]["x"] - townList[proposedNextPoint]["x"])^2 + (townList[finish]["y"] - townList[proposedNextPoint]["y"])^2)
end

# Run A* from town start to finish, returning the explored region and costs to reach each town in it
#= Working! Woohoo!! This returns the list of all towns searched so you just need to set it up
   to work backwards through the returned list from the finish to the start (possible edge cases
   of a node being reached by two routes, this is causing slightly inefficient paths in some edge 
   cases but it's fine) and we're up and running. I'd also like to figure out a cool way of plotting
   /animating this because that would just be fun =#
function aStar(start, finish, links, townList)
    frontier = [[0, start]]    # Priority queue, first in each tuple is the priority and second is the town
    cameFrom = Dict{Int64, Any}(start => nothing)
    costSoFar = Dict(start => 0.0)

    while length(frontier) != 0

        currentPriorityEntry, currentIndex = findmin(frontier)
        current = currentPriorityEntry[2]

        splice!(frontier, currentIndex)

        if current == finish
            break
        end

        possibleNextTowns = []
        # I'd say there's a better way of finding the possibilities but this'll do
        #println(current)
        for i in range(1, length(links[current,:]))
            if links[current,i] != 0
                push!(possibleNextTowns, i)
            end
        end
        for next in possibleNextTowns
            newCost = costSoFar[current] + links[next, current]
            
            if next ∉ keys(costSoFar) || newCost < costSoFar[next]
                costSoFar[next] = floor(newCost)
                #println("Cost so far = " * string(costSoFar[next]))
                #println("newCost = " * string(newCost))

                priority = floor(newCost) + heuristicCost(next, finish, townList)
                #println("heuristic = " * string(heuristicCost(next, finish, townList)))
                #println("frontier = " * string(frontier))
                #println("priority = " * string(priority))
                #println("next = " * string(next))

                push!(frontier, [priority, next])
                cameFrom[next] = current
            end
        end
    end

    return cameFrom, costSoFar

end

# Run the A* function and work backwards through the explored region it returns to find the path
function findPathBetweenTwoTowns(start, finish, links, townList)
    cameFrom, costSoFar = aStar(start, finish, links, townList)

    finalSequence = [finish]
    while finalSequence[1] != start
        pushfirst!(finalSequence, cameFrom[finalSequence[1]])
    end
    return finalSequence
end





#------------------------------------------------------------------------------------------
#--------------------------------- Map Generation -----------------------------------------
#------------------------------------------------------------------------------------------
# Instantiate nTowns number of towns with random parameters and return the list of them
function generateTownList(nTowns)
    townList = []
    for i in range(1,nTowns)
        initN = Random.rand(range(100.0, maxInitPopulation))
        initP = Random.rand(range(1.0,maxProdRatePerPerson), numAssets)
        town = Dict("x" => Random.rand(range(1,mapWidth)),
                    "y" => Random.rand(range(1,mapHeight)),

                    "population" => initN,
                    "money" => Random.rand(range(1,maxInitMoney)),

                    "conRates"  => Random.rand(range(0.5,maxConPerPerson), numAssets),
                    "prodRates" => initP,

                    "rP" => Random.rand(range(0.01,maxrP), numAssets),
                    "maxProdRatesPerPerson" => [Random.rand(range(initP[i], maxProdRatePerPerson)) for i in 1:numAssets],
                    #"maxAbsoluteProdRates" => Random.rand(range(1.0, maxAbsoluteProdRate), numAssets),
                    
                    "Nhistory" => [initN for i in 1:delayLength],
                    "Phistory" => [initP for i in 1:delayLength])
        push!(townList, town)
        #print(town)
    end
    return townList
end

# Add a link to the link matrix between each town and its nearest neighbour in townList
function findNearestTowns(towns, links)
    #links = Array{Float64}(undef, length(towns), length(towns))

    for i in range(1, length(towns))
        town = towns[i]

        currentShortestDist = 1000000
        currentNearestTown = 1

        for j in range(1, length(towns))
            otherTown = towns[j]

            distance = (town["x"] - otherTown["x"])^2 + (town["y"] - otherTown["y"])^2

            if distance < currentShortestDist
                if town != otherTown
                    currentNearestTown = j
                    currentShortestDist = distance
                end
            end 
        end
        links[i,currentNearestTown] = true
        links[currentNearestTown,i] = true 
    end
    return links
end

# Loop through townList and link matrix and plot it
function drawNetwork(towns, links, traderList)
    scatter(0,0)
    for i in range(1, length(towns))
        scatter!([towns[i]["x"]], [towns[i]["y"]], color="blue")    
        for j in range(1, length(towns))
            if floor(links[i,j])  != 0
                plot!([towns[i]["x"], towns[j]["x"]], [towns[i]["y"], towns[j]["y"]], color="blue")
            end
        end
    end
end

# Generate a matrix storing the distance between every pair of matrices (more efficient to
# do this once at the start so doing it now)
function calculateDistanceMatrix(towns)
    distances = Array{Float64}(undef, length(towns), length(towns))
    totalDistance = 0

    for i in range(1, length(towns))
        town = towns[i]

        for j in range(1, i)
            if i != j
                otherTown = towns[j]

                distance = (town["x"] - otherTown["x"])^2 + (town["y"] - otherTown["y"])^2
                distances[i,j] = distance
                distances[j,i] = distance
                totalDistance += distance
            end
        end 
    end
    return distances, totalDistance/(length(towns)^2)
end

# Improve the map by randomly adding links based on distance between towns
function addConnections(links, distances, meanDist)
    for i in range(1,Int(sqrt(length(links))))
        for j in range(1,i-1)
             
            #= Pseudocode: base probability that a link is added between two towns = 0.25
                           scale base probability by comparison to mean distance =#
            probLinkAdded = 0.5
            
            probLinkAdded = probLinkAdded / (distances[Int(i),Int(j)]/meanDist)

            threshold = rand(range(0.01,1, 100))
            metropolisValue = rand(range(0.01,1, 100))*probLinkAdded
            
            if metropolisValue > threshold
                links[i,j] = true
                links[j,i] = true
            end
        end
    end
    return links
end

# Something going wrong here, looks like all entries are being set as distances rather than jsut the nonzero entries
# Try setting links[i,j] = floor[links[i,j]] before checking zero?
# Take links (binary with 1 representing a link between towns and 0 meaning none) and combine it with
# distances so that each link is now the distance between the two towns (0 still means no link)
function addDistancesToLinks(links, distances)
    for i in range(1,Int(sqrt(length(links))))
        for j in range(1,i)
            links[i,j] = floor(links[i,j])
            if links[i,j] != 0
                links[i,j] = distances[i,j]
                links[j,i] = distances[i,j]
            end
        end
    end
    return links
end

# Loop through townList and run A* between all pairs, add a link to join any unreachable towns
# or subnetwork to the network
function ensureContinuous(links, townList, distances)
    start = 1
    for finish in range(2, length(townList))
        cameFrom, costSoFar = aStar(start, finish, links, townList)

        # Worth adding a check to see if length = len(townList) or something to save extra loops if possible

        if finish ∉ keys(cameFrom)
            #= This is just really cool to see where the frontier is
            frontier = Dict()
            for key in keys(cameFrom)
                if key ∉ values(cameFrom)
                    frontier[key] = costSoFar[key]
                end
            end
            closestInFrontier = findmin(frontier)[2]

            println("closest in frontier = " * string(closestInFrontier))
            println("Frontier = " * string(frontier))
            for i in range(1, length(townList))
                scatter!([townList[i]["x"]], [townList[i]["y"]], color="blue")    
                for j in range(1, length(townList))
                    if links[i,j]  != 0
                        plot!([townList[i]["x"], townList[j]["x"]], [townList[i]["y"], townList[j]["y"]], color="blue")
                    end
                end
            end
            for town in keys(frontier)
                scatter!([townList[town]["x"]],[townList[town]["y"]], color="red")
            end
            scatter!([townList[1]["x"]],[townList[1]["y"]], color="orange")
            scatter!([townList[closestInFrontier]["x"]],[townList[closestInFrontier]["y"]], color="yellow")
            gui()
            readline() =#

            # Find closest in explored region
            closest = start
            for town in keys(cameFrom)
                if distances[town, finish] < distances[closest, finish]
                    closest = town
                end
            end

            links[finish, closest] = 1.0
            links[closest, finish] = 1.0
        end
    end
    return links
end

# Calculate a matrix to store the distance of the route between any two towns, precomputed here for efficiency
function pathDistanceMatrix(links, townList, distances)
    returnMatrix = Array{Float64}(undef, length(townList), length(townList))

    for town in range(1,length(townList))
        for otherTown in range(1, town)
            distance = 0
            path = findPathBetweenTwoTowns(town, otherTown, links, townList)
            for i in range(2,length(path))
                distance += distances[path[i],path[i-1]]
            end
        returnMatrix[town, otherTown] = distance
        returnMatrix[otherTown, town] = distance
        end
    end
    #println(returnMatrix)
    return returnMatrix
end

function generateWorldMapNetwork(townN)
    # Generate list of randomly distributed towns
    townList = generateTownList(townNum)

    # Create empty matrix of links between towns and loop through it to link each town with its nearest neighbour
    links = Array{Float64}(undef, townNum, townNum)
    links = findNearestTowns(townList, links)

    # Generate matrix representing distance between each town and return the mean distance
    distanceMatrix, meanDistance = calculateDistanceMatrix(townList)

    # Improve the network a bit by using a metropolis check to add new links between towns based on distance
    # between the towns vs mean distance between every pair of towns
    links = addConnections(links, distanceMatrix, meanDistance)


    #= Add an extra town with no connections just to test the A* making sure it's all continuous
    townList = push!(townList, Dict("x" => Random.rand(range(1,mapWidth)),
                                    "y" => Random.rand(range(1,mapHeight))))
    println("Links 1 = " * string(links))
    links = vcat(links, zeros(Float64, 1, townNum))
    links = hcat(links, zeros(Float64, townNum+1))
    distanceMatrix, meanDistance = calculateDistanceMatrix(townList)
    println("Links 2 = " * string(links))
    =#

    # Make sure all towns are reachable, i.e. whole network is continuous
    links = ensureContinuous(links, townList, distanceMatrix)

    #pathLengths = pathDistanceMatrix(links, townList, distanceMatrix)

    # Convert links from binary 1 = link, 0 = no link to storing the distance between the towns (0 still = no link)
    links = addDistancesToLinks(links, distanceMatrix)
    println(links)
    return townList, links, distanceMatrix, 1
end


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

townList, links, distanceMatrix, pathDistances = generateWorldMapNetwork(townNum)
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
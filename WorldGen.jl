using Random
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))


#------------------------------------------------------------------------------------------
#--------------------------------- Map Generation -----------------------------------------
#------------------------------------------------------------------------------------------
# Instantiate nTowns number of towns with random parameters and return the list of them
function generateTownList(nTowns, mapWidth, mapHeight)
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


# Generate a matrix storing the distance between every pair of towns (more efficient to
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
             
            #= Pseudocode: base probability that a link is added between two towns = 0.5
                           scale base probability by comparison to mean distance =#
            probLinkAdded = 0.25
            
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
        
        println("Finish = " * string(finish))
        println("Came from keys = " * string(keys(cameFrom)))
        if finish ∉ keys(cameFrom)
            println("discontinuity flagged")
            # This is just really cool to see where the frontier is
            frontier = Dict()
            for key in keys(cameFrom)
                if key ∉ values(cameFrom)
                    frontier[key] = costSoFar[key]
                end
            end
            closestInFrontier = findmin(frontier)[2]

            ##println("closest in frontier = " * string(closestInFrontier))
            #println("Frontier = " * string(frontier))
            for i in range(1, length(townList))
                scatter!([townList[i]["x"]], [townList[i]["y"]], color="blue")    
                for j in range(1, length(townList))
                    if floor(links[i,j])  != 0
                        plot!([townList[i]["x"], townList[j]["x"]], [townList[i]["y"], townList[j]["y"]], color="blue")
                    end
                end
            end
            for town in keys(frontier)
 
                scatter!([townList[town]["x"]],[townList[town]["y"]], color="red")
            end
            scatter!([townList[1]["x"]],[townList[1]["y"]], color="orange")
            scatter!([townList[closestInFrontier]["x"]],[townList[closestInFrontier]["y"]], color="yellow")
            #gui()
            #readline() 

            # Find closest in explored region
            closest = start
            for town in keys(cameFrom)
                if distances[town, finish] < distances[closest, finish]
                    closest = town
                end
            end

            println("Closest = " * string(closest))

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

function generateWorldMapNetwork(townNum, mapWidth, mapHeight)
    # Generate list of randomly distributed towns
    townList = generateTownList(townNum, mapWidth, mapHeight)

    # Create empty matrix of links between towns and loop through it to link each town with its nearest neighbour
    links = Array{Float64}(undef, townNum, townNum)
    links = findNearestTowns(townList, links)

    # Generate matrix representing distance between each town and return the mean distance
    distanceMatrix, meanDistance = calculateDistanceMatrix(townList)

    # Improve the network a bit by using a metropolis check to add new links between towns based on distance
    # between the towns vs mean distance between every pair of towns
    links = addConnections(links, distanceMatrix, meanDistance)


    #=town = Dict("x" => Random.rand(range(1,mapWidth)),
                    "y" => Random.rand(range(1,mapHeight)),

                    "population" => 1,
                    "money" => Random.rand(range(1,maxInitMoney)),

                    "conRates"  => Random.rand(range(0.5,maxConPerPerson), numAssets),
                    "prodRates" => 1,

                    "rP" => Random.rand(range(0.01,maxrP), numAssets),
                    "maxProdRatesPerPerson" => [Random.rand(range(1, maxProdRatePerPerson)) for i in 1:numAssets],
                    #"maxAbsoluteProdRates" => Random.rand(range(1.0, maxAbsoluteProdRate), numAssets),
                    
                    "Nhistory" => [1 for i in 1:delayLength],
                    "Phistory" => [1 for i in 1:delayLength])
    push!(townList, town)=#

    # Make sure all towns are reachable, i.e. whole network is continuous
    links = ensureContinuous(links, townList, distanceMatrix)

    #pathLengths = pathDistanceMatrix(links, townList, distanceMatrix)

    # Convert links from binary 1 = link, 0 = no link to storing the distance between the towns (0 still = no link)
    links = addDistancesToLinks(links, distanceMatrix)
    println(links)
    return townList, links, distanceMatrix, 1
end

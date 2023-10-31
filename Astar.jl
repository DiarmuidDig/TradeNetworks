using Random
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

#------------------------------------------------------------------------------------------
#------------------------------------------ A* --------------------------------------------
#------------------------------------------------------------------------------------------

#= Can add an extra cost (or reduce cost) for each city passed through if you want to tailor the behaviour
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
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))







#------------------------------------------------------------------------------------------
#---------------------------------- Instantiate Traders -----------------------------------
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






#------------------------------------------------------------------------------------------
#------------------------------------ Trader Movement -------------------------------------
#------------------------------------------------------------------------------------------

# Move trader position speed increments along the vector to its immediate target
function moveTrader(trader)
    push!(trader["xPositionHistory"], trader["x"])
    push!(trader["yPositionHistory"], trader["y"])

    trader["x"] += trader["speed"] * trader["currentVector"][1]
    trader["y"] += trader["speed"] * trader["currentVector"][2]

    return trader
end

# Precalculate the vector from the current position (a town) to their immediate target (the next town they're heading for)
function setTraderVector(trader, townList)
    trader["currentVector"] = [townList[trader["immediateTarget"]]["x"] - townList[trader["currentTown"]]["x"], 
                               townList[trader["immediateTarget"]]["y"] - townList[trader["currentTown"]]["y"]]
    
    # Comment these two lines for unnormalised vector, you'll also prob need to adjust the speed in moveTrader()
    normalisationConst = sqrt(trader["currentVector"][1]^2 + trader["currentVector"][2]^2)
    trader["currentVector"] = [trader["currentVector"][1]/normalisationConst, trader["currentVector"][2]/normalisationConst]
    
    return trader
end



#------------------------------------------------------------------------------------------
#----------------------------------- Trader Behaviour -------------------------------------
#------------------------------------------------------------------------------------------

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




#------------------------------------------------------------------------------------------
#------------------------------------- Run Traders ----------------------------------------
#------------------------------------------------------------------------------------------

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
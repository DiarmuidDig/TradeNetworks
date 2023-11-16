using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

townHistory = []

function generateTownHistoryStorageObj(townList, delayLength, simDuration)
    # Empty storage object for one town
    numAssets = length(townList[1]["prodRates"])
    storageTemplate = [zeros(Float32, 1, delayLength + simDuration), zeros(Float32, numAssets, delayLength + simDuration)]


    townHistories = [storageTemplate for i in range(1, length(townList))]
    for i in range(1, length(townList))
        # Set the delay buffer at the start of the storage for each town

        # Population
        townHistories[i][1][1:delayLength] .= townList[i]["population"]
        for j in range(1, numAssets)
            townHistories[i][2][j,1:delayLength] .= townList[i]["prodRates"][j]
        end
            println(townHistories[i])
    end

end
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

townHistory = []

function generateTownHistoryStorageObj(townList, delayLength, simDuration)
    numAssets = length(townList[1]["prodRates"]) 
    
    # This isn't an efficient way to do this but every clever trick I tried bit me on the arse
    # List comprehension made a change to one town pass to all others and not declaring the storage
    # object every loop reset every town's entry to the current one being added. Improve later
    # I also hoped to declare townHistories at full townList length instead of pushing elements but no joy for now
    townHistories = Array{Vector{Matrix{Float32}}}(undef, 0)
    for i in range(1,length(townList))
        storageTemplate = [zeros(Float32, 1, delayLength + simDuration), zeros(Float32, numAssets, delayLength + simDuration)]
        storageTemplate[1][1:delayLength] .= townList[i]["population"]
        for j in range(1, numAssets)
            storageTemplate[2][j,1:delayLength] .= townList[i]["prodRates"][j]
        end
        
        push!(townHistories, storageTemplate)
        #townHistories[i] = storageTemplate
    end

    println(townHistories)
    return townHistories

end
using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

townHistory = []

function generateTownHistoryStorageObj(townList, delayLength, simDuration)
    # Empty storage object for one town
    #numAssets = length(townList[1]["prodRates"]) Commented to make testing below easier without needing to get a full townlist by switching back to the main file to run
    numAssets = 2
    # Type should be float but set to int for testing
    storageTemplate = [zeros(Int, 1, delayLength + simDuration), zeros(Int, numAssets, delayLength + simDuration)]

    # Trying to figure out how to assign to one town in the storage object without affecting the others
    # Way the fuck more complicated than it should be
    townHistories = [storageTemplate for i in range(1, length(townList))]
    println(townHistories)
    townHistories[1][1][1]=1
    #println(townHistories[1][1])
    #println(townHistories[2][1])
    println(townHistories)


    # Okay let's see how it works with a simpler list of lists
    # Loop below commented to not have to pass a full townlist by swapping back to the main file
    test = [ [[0 0 0 0], [0 0 0 0; 0 0 0 0]], [[0 0 0 0], [0 0 0 0; 0 0 0 0]] ]
    println(test)
    test[1][1][1]=1
    #println(test[1][1][1])
    println(test)


    #= What. The. Fuck. Is. happening. I can't see any reason for the townHistory bit to assign to both
    population histories at all, let alone when it isn't doing that for the test. The test vector set up 
    should be identical to the storage and it's still happening so I really don't have a clue. My best
    bet is to start printing types of everything, start with the overall vectors and matrices and work
    inwards, and see if there's any way that the stoage and test objects are different. After that you pray
    and hope that wiping the kernel fixed it (yep, we're resorting to a nonexistent kernal being wiped).
    =# 
    
    #=for i in range(1, length(townList))
        # Set the delay buffer at the start of the storage for each town

        # Population
        townHistories[i][1][1:delayLength] .= townList[i]["population"]
        #println(townHistories[i])
        for j in range(1, numAssets)
            townHistories[i][2][j,1:delayLength] .= townList[i]["prodRates"][j]
        end
        #println("Within loop: " * string(townHistories)) 
    end
    #println("After loop: " * string(townHistories))=#
end

generateTownHistoryStorageObj([1,1], 2, 2)
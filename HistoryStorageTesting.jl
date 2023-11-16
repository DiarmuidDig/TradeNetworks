using Random


#= Here we go, a new system to store the full history of the towns at each tick in teh simulation.
Each town has one of these objects, a list of an array and a matrix. The array stores the population
of the town at each tick and the matrix stores the production rates, each row storing one asset and
each column storing the value of that asset at one tick. This can be easily extended to arbitrary size
(even during the sim, just vcat a row of zeroes to the matrix to add a whole new asset to the system)
and to expand with the scope of the simulation (can store asset storage histories m.sh. by just
adding a new matrix).
How to access each element and type of element is documented below. Only problem with this system is
that you need to pass the current tick around to index the lists but that's fine. =#

function printTownHistoryDocs()
    delayLength = 3
    maxProdRatePerPerson = 10.0
    numAssets = 2
    numTowns = 2

    
# Setting up a sample container for one town to experiment with (full storage object will 
# be a list of these, I think)
# The construction methods here are good practice but definitely not going to be the production version
Phistory = zeros(Float32, numAssets, delayLength)
Nhistory = zeros(Float32, 1, delayLength)

# Set dummy values at each index so I can demonstrate the indexing below
for i in range(1, delayLength)
    Nhistory[i] = 1.0 + i*0.1
    for j in range(1,numAssets)
        Phistory[j,i] = j+1.0 + i*0.1
    end
end

townHistory = [Nhistory, Phistory]
println("Complete demo object (to show indexing below): " * string(townHistory))


# Take some sample slices to have as mini-documentation of how the storage containers work
# This is all ignoring accessing the container for the given town we want

# Access Nhistory of a given town
println("Nhistory of a town = " * string(townHistory[1]))

# Access Nhistory of a given town at a given tick
println("Nhistory of a town at time x (x = 2 here): " * string(townHistory[1][2]))

# Access the latest entry in Nhistory
# This is either the current or most recent non-current value for N
println("Nhistory[-1]: " * string(last(townHistory[1]))) 
println("Nhistory[-1]: " * string(townHistory[1][end]))


# Access Phistory of all assets in the town
println("Phistory for all assets: " * string(townHistory[2]))

# Access Phistory for one asset
println("Phistory for one asset: " * string(townHistory[2][2,:]))

# Access the latest Phistory for one asset, see Nhistory[-1] note for what this corresponds to
println("Phistory[-1] for one asset: " * string(last(townHistory[2][1,:])))
println("Phistory[-1] for one asset: " * string(townHistory[2][1,end]))

# Access Phistory for one asset at a given tick
println("Phistory for one asset at a given tick: " * string(townHistory[2][1,2]))

# Access Phistory for all assets at one tick
println("Phistory for all assets at one tick: " * string(townHistory[2][:,2]))

# Access Phistory latest Phistory for all assets
println("Phistory [-1] for all assets: " * string(townHistory[2][:,end]))

# Adding columns
# Add one value to Nhistory
townHistory[1] = hcat(townHistory[1], 1.4)
println("Push to Nhistory: " * string(townHistory[1]))

# Add new set of values to Phistory
# Have to do it a whole column at a time with dynamic sizing, can do one value
# and a column of zeroes but that gets messy with reassigning the other values
# instead of pushing them. System below allows for single values
townHistory[2] = hcat(townHistory[2], [2.4; 3.4])
println("Push to Phistory: " * string(townHistory[2]))



# Let's see about initialising it to the full final size
println("Testing initialising the object at full size")
simDuration = 5  # what's called animFrameCount in the runSim file, the number of ticks in this running
numAssets = 2
delayLength = 3

townHistory2 = [zeros(Float32, 1, delayLength + simDuration), zeros(Float32, numAssets, delayLength + simDuration), ]
println("Complete demo object initialised at final size: " * string(townHistory2))

# Access elements in the same way as above, just swap out end for the current tick value of the sim

# Assign a whole column of Phistory at once
testVector = [1.0; 1.0]
townHistory2[2][:,2] = testVector
println("Assign a whole column of Phistory at once: " * string(townHistory2))


end

#printTownHistoryDocs()

# Also very much worth looking at data structures that could hold stuff like this more efficiently
# but for now I'm happy enough to go with this.

#= Also for dynamic size I think having the N and P chunk separate works (although I'll need to
test even that to make sure that I'm allowed to have the array and matrix be different widths
if I want to push to them one at a time during the update process), but if I do go for all zeroes
at final size that are reassigned as we go that isn't a concern anymore. I could have the first
row of a matrix for each town be N and the rest P (index offset by +1 from that asset's index in
assetList). No idea if htat's actually any better/nicer/faster but it is an option. =#

using Random

delayLength = 3
maxProdRatePerPerson = 10.0
numAssets = 2
numTowns = 2

initP = Random.rand(range(1.0,maxProdRatePerPerson), numAssets)


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
# Have to do it a whole column at a time, can do one value
# and a column of zeroes but that gets messy with reassigning the other values
# instead of pushing them
townHistory[2] = hcat(townHistory[2], [2.4; 3.4])
println("Push to Phistory: " * string(townHistory[2]))



# Let's see about initialising it to the full final size
println("Testing initialising the object at full size")
simDuration = 5  # what's called animFrameCount in the runSim file, the number of ticks in this running
numAssets = 2
delayLength = 3

Phistory = zeros(Float32, numAssets, delayLength + simDuration)
Nhistory = zeros(Float32, 1, delayLength + simDuration)
#townHistory2 = [Nhistory, Phistory]
townHistory2 = [zeros(Float32, numAssets, delayLength + simDuration), zeros(Float32, 1, delayLength + simDuration)]
println("Complete demo object initialised at final size: " * string(townHistory2))





#= Next, look at initialising it to animFrameCount (want to have both options in case I do need 
dynamic size at some stage). Then bring it all together and create the master storage object with 
one of these per town and double check that everything above still works. Then, finally, make some
functions to black-box all this stuff away and let me do it nicely in other scripts =#

# Also very much worth looking at data structures that could hold stuff like this more efficiently
# but for now I'm happy enough to go with this.

#= Also for dynamic size I think having the N and P chunk separate works (although I'll need to
test even that to make sure that I'm allowed to have the array and matrix be different widths
if I want to push to them one at a time during the update process), but if I do go for all zeroes
at final size that are reassigned as we go that isn't a concern anymore. I could have the first
row of a matrix for each town be N and the rest P (index offset by +1 from that asset's index in
assetList). No idea if htat's actually any better/nicer/faster but it is an option. =#

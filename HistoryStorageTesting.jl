using Random

delayLength = 3
maxProdRatePerPerson = 10.0
numAssets = 2
numTowns = 2

initP = Random.rand(range(1.0,maxProdRatePerPerson), numAssets)

# Worth noting that generating the object according to animFrameCount or totalTickNum might be simple for a good efficiency boost

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

# Access Phistory of all assets in the town
println("Phistory for all assets: " * string(townHistory[2]))

# Access Phistory for one asset
println("Phistory for one asset: " * string(townHistory[2][1,:]))

# Access Phistory for one asset at a given tick
println("Phistory for one asset at a given tick: " * string(townHistory[2][1,2]))

# Access Phistory for all assets at one tick
println("Phistory for all assets at one tick: " * string(townHistory[2][:,2]))


#= Next, need to finish out the above docs with how to access the last element of all combos
(or really just th elast tick, probably). Then figure out the methods for adding columns, then
look at initialising it to animFrameCount (want to have both options in case I do need dynamic
size at some stage). The bring it all together and create the master storage object with one
of these per town and double check that everything above still works. Then, finally, make some
functions to black-box all this stuff away and let me do it nocely in other scripts =#

# Also very much worth looking at data structures that could hold stuff like this more efficiently
# but for now I'm happy enough to go with this.

#= Also for dynamic size I think having the N and P chunk separate works (although I'll need to
test even that to make sure that I'm allowed to have the array and matrix be different widths
if I want to push to them one at a time during the update process), but if I do go for all zeroes
at final size that are reassigned as we go that isn't a concern anymore. I could have the first
row of a matrix for each town be N and the rest P (index offset by +1 from that asset's index in
assetList). No idea if htat's actually any better/nicer/faster but it is an option.
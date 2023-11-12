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

# Access history of all assets in the town
println("Phistory for all assets: " * string(townHistory[2]))

# Access history for one asset
println("Phistory for one asset: " * string(townHistory[2][1,:]))

# Access history for one asset at a given tick
println("Phistory for one asset at a given tick: " * string(townHistory[2][1,2]))

# Access history for all assets at one tick
println("Phistory for all assets at one tick: " * string(townHistory[2][:,2]))
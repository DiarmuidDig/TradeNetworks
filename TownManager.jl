using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))

function generateTownHistoryStorage(townList)
    

end


#= What's a good method to store the town histories at each step? Let's think about what this object needs
to handle. It needs to handle
List of slots, one for each town
In each town we have a 1D array for the population at each tick
We also have a matrix for the production rates of the assets, eahc row storing a different asset, each column representing a tick
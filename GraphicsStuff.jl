using Plots
using Statistics
Plots.default(legend=false)
#Plots.default(show=true)
Plots.default(xlims=(0,500))
#Plots.default(ylims=(0,500))


#------------------------------------------------------------------------------------------
#--------------------------------- Static Drawing Methods ---------------------------------
#------------------------------------------------------------------------------------------

# Loop through townList and link matrix and plot it
function drawNetwork(towns, links)
    scatter(0,0)
    for i in range(1, length(towns))
        scatter!([towns[i]["x"]], [towns[i]["y"]], color="blue")    
        for j in range(1, length(towns))
            if floor(links[i,j])  != 0
                plot!([towns[i]["x"], towns[j]["x"]], [towns[i]["y"], towns[j]["y"]], color="blue")
            end
        end
    end
end

# Draw traders as they exist in that tick (no animation or anything, just plot them at that moment)
function drawTraders(traderList)
    for trader in traderList
        scatter!([trader["x"]], [trader["y"]], color="red") 
    end
end


#= I'm pretty sure this is in no way how multiple dispatch is meant to be used. I'm fully aware that this is going to
be unreadable and I'll forget these different versions of the method in a day but I want to start using it to learn
and this is a good opportunity to do it badly so I can do it better next time. =#
# Also probably worth looking at passing the towns themselves as opposed to indices and having to pass all of townList at the same time

# When a town and number are given, take the number as the index of an asset in assetList to be plotted for just that town
function drawTownHistory(town, asset::Number, townList)
    #townToPlot = townList[town]
    #assetHistory  = townToPlot[]
    #plot(range(1,length(town["Nhistory"]), ))



end

# When just a town is given, take it that the population history of that town should be plotted
function drawTownHistory(town::Number, townList)
    townToPlot = townList[town]
    plot(range(1,length(townToPlot["Nhistory"])), townToPlot["Nhistory"])
    print("ran")
    gui()
    readline()

end

# When just a townList is given, take it that the population histories of all towns in the list (not necessarily
# all towns in the world) should be plotted
function drawTownHistory(townList)


end

# When a townList and number are given, plot the asset at index number in asset List for all towns in the list
function drawTownHistory(townList, asset)

end

#------------------------------------------------------------------------------------------
#---------------------------------------- Animation ---------------------------------------
#------------------------------------------------------------------------------------------


# I think it would be good to refactor this. Switch it to store a list of
# coordinates at each timestep, that'll show the overall progression over time while just having one x and
# one y to deal with, that can be plugged straight in to show the whole system without looping though traders
function generateAnimationGif(townList, links, traderList)
    anim = @animate for i = 1:animFrameCount
        drawNetwork(townList, links)
        scatter!([townList[traderList[1]["finalTargetHistory"][i]]["x"]], [townList[traderList[1]["finalTargetHistory"][i]]["y"]], color="orange")
        for trader in traderList
            scatter!((trader["xPositionHistory"][i], trader["yPositionHistory"][i]), color="red")
        end
    end 
    gif(anim, "testAnimation.gif", fps=50)

end
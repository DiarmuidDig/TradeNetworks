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



#------------------------------------------------------------------------------------------
#---------------------------------------- Animation ---------------------------------------
#------------------------------------------------------------------------------------------

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
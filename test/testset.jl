
plotpath(x) = joinpath(ENV["HOME"], "plots/", x)

function main()
    @testset "PlotKitGL" begin
        @test main3()
        @test main4()
#        @test main3()
    end
end

# simple chart
function main1()
    println("main1")

    return true
end


# simple chart with labels
function main2)
    println("main2")

    return true
end




# chart with manually labeled lines
function main3()
    println("main3")
    function getdata(k)
        x = collect(0:0.01:10)
        y = k*sin.(x*(k/10+1) .+ k)
        return Point.(zip(x, y))
    end
    data = [getdata(k) for k=1:10]
    ad = draw(Chart(data))
    xdes = 2
    llp = LineLabelPositioner(ad, PointList.(data), xdes)
    for i = 1:length(data)
        drawlabel(ad, llp.markerpositions[i], i)
    end
    save(ad, plotpath("test_charts3.pdf"))
    return true
end



# bar chart
function main4()
    println("main4")
    x = collect(0:10)
    y = x.*x .+ 1
    data = PointList(Point.(zip(x, y)))
    bc = BarChart(data)
    ad = draw(bc)
    save(ad,  plotpath("test_charts4.pdf"))
    return true
end

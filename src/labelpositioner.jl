
module LabelPositioner

using PlotKitCairo: Point, PointList
using PlotKitAxes: AxisMap, AxisDrawable
using PlotKitDiagrams

export LineLabelPositioner

Base.@kwdef mutable struct LineLabelPositioner
    f    # function f(i,x) returns the y coordinate of line i at point x
    xdes
    n    # number of labels
    separation = 10
    searchstep = 2
    markerpositions = Dict()   # maps line number i to existing marker position Point
end



getentry(a::Vector, i) = a[i]
getentry(a::Number, i) = a

function interpolate(pl::PointList, t)
    x = [a.x for a in pl.points]
    y = [a.y for a in pl.points]
    return interpolate(x, y, t)
end

function interpolate(x::Vector, y::Vector, t)
    i = searchsortedlast(x, t)
    if x[i] == t
        return y[i]
    end
    if i == length(x)
        return y[end]
    end
    return interpolate(x[i], y[i], x[i+1], y[i+1], t)
end

interpolate(x1,y1,x2,y2,d) = ((x2-d)*y1 - (x1-d)*y2)/(x2-x1)


# given a line, and a list of existing marker positions, return the next marker position
function setnextmarkerposition(llp::LineLabelPositioner, i, ax::AxisMap)
    norm(a::Point) = sqrt(a.x*a.x + a.y*a.y)
    pointonline(x) = ax(Point(x, llp.f(i, x)))
    mpos = pointonline(getentry(llp.xdes, i))
    while any(a -> norm(mpos - a) < 2 * llp.separation,  values(llp.markerpositions))
        mpos = pointonline(ax.fxinv(mpos.x + llp.searchstep))
    end
    llp.markerpositions[i] = mpos
end

function setmarkerpositions(llp::LineLabelPositioner, ax::AxisMap)
    for i=1:llp.n
        setnextmarkerposition(llp, i, ax)
    end
end

function LineLabelPositioner(ad::AxisDrawable, pll::Vector{PointList}, xdes; kw...)
    f = (i,x) -> interpolate(pll[i],x)
    llp = LineLabelPositioner(; f, xdes, n = length(pll), kw...)
    setmarkerpositions(llp, ad.axis.ax)
    return llp
end













end


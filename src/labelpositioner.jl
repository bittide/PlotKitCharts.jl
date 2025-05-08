
module LabelPositioner

using PlotKitCairo: Point, PointList, inbox
using PlotKitAxes: AxisMap, AxisDrawable
using PlotKitDiagrams

export LineLabelPositioner

Base.@kwdef mutable struct LineLabelPositioner
    f    # function f(i,x) returns the y coordinate of line i at point x
    xmin # array mapping i to min allowed pos
    xmax
    xdes
    n    # number of labels
    margin = 40 # required distance from end of line
    separation = 10
    searchstep = 2
    steps_away_from_outside_axes = 20  # take this many steps away from points where line leaves axes
    markerpositions = Dict()   # maps line number i to existing marker position Point
end



getentry(a::Vector, i) = a[i]
getentry(a::Number, i) = a

function is_in_domain(pl::PointList, q)
    if q < pl.points[1].x || q > pl.points[end].x
        return false
    end
    return true
end

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

# are any of x[i-m],...,x[i+m] true?
function close_true(x, i, m)
    n = length(x)
    for j=max(i-m,1):min(i + m,n)
        if x[j]
            return true
        end
    end
    return false
end

    
# given a line, and a list of existing marker positions, return the next marker position
function setnextmarkerposition(llp::LineLabelPositioner, i, ax::AxisMap, databox)
    norm(a::Point) = sqrt(a.x*a.x + a.y*a.y)
    pointonline(x) = ax(Point(x, llp.f(i, x)))
    too_close_to_another_marker(p) = any(a -> norm(p - a) < 2 * llp.separation,  values(llp.markerpositions))
    function outside_axes(p)
        p2 = ax.finv(p)
        if !inbox(p2, databox)
            return true
        end
        return false
    end

    indomain(x_scr) = ax.fx(llp.xmin[i]) + llp.margin < x_scr <  ax.fx(llp.xmax[i]) - llp.margin

    
    # in screen coords
    screen_xmin = ax.fx(databox.xmin) + llp.searchstep
    screen_xmax = ax.fx(databox.xmax) - llp.searchstep
    all_x_positions = collect(range(screen_xmin, screen_xmax, step = llp.searchstep))
    all_points_on_line = [pointonline(ax.fxinv(a)) for a in all_x_positions if indomain(a)]

    # list of booleans corresponding to all_points_on_line
    points_outside = [outside_axes(p) for p in all_points_on_line]
    nearly_outside = [close_true(points_outside, i, llp.steps_away_from_outside_axes) for i=1:length(points_outside)]

    # list of points
    good_points = [all_points_on_line[i] for i=1:length(all_points_on_line) if !nearly_outside[i]]
    not_too_close = [p for p in good_points if !too_close_to_another_marker(p)]

    # pick closest
    xdes = ax.fx(getentry(llp.xdes, i))
    if length(not_too_close) > 0
        val, ind = findmin(p -> abs(p.x - xdes), not_too_close)
        llp.markerpositions[i] = not_too_close[ind]
    else
        llp.markerpositions[i] = pointonline(xdes)
    end
end

function setmarkerpositions(llp::LineLabelPositioner, ax::AxisMap, databox)
    for i=1:llp.n
        setnextmarkerposition(llp, i, ax, databox)
    end
end

function LineLabelPositioner(ad::AxisDrawable, pll::Vector{PointList}, xdes; kw...)
    f = (i,x) -> interpolate(pll[i],x)
    xmin = [a.points[1].x for a in pll]
    xmax = [a.points[end].x for a in pll]
    llp = LineLabelPositioner(; f, xdes, xmin, xmax, n = length(pll), kw...)
    setmarkerpositions(llp, ad.axis.ax, ad.axis.box)
    return llp
end













end


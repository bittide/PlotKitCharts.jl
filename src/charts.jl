# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Charts

using PlotKitCairo: ChainList, Color, LineStyle, PlotKitCairo, Point, PointList, allowed_kws, ati, circle, colormap, draw, input, line, setoptions!, text, qsave
using PlotKitAxes: Axis, AxisDrawable, PlotKitAxes, drawaxis, setclipbox

using ..LabelPositioner: LineLabelPositioner

export Chart, MultiChart, drawlabel, drawchartlabels, plot

Base.@kwdef mutable struct Chart
    linestyle = i -> LineStyle(colormap(i) , 1)
    markerradius = i -> 0
    markerfillcolor = i -> nothing
    markerlinestyle = i -> nothing
    markerscaletype = i -> :none
    labeled = true
    xdes = nothing
    labelfontname = "Sans"
    labelfontsize = 9
    labelradius = 8
    labeltext = i -> string(i)
    labelcolor = i -> colormap(i)
    labelseparation = 10
    pll::Vector{PointList}   # pointlist list
    axis = nothing
    labelpositioner = nothing
end

##############################################################################
# purely convenience functions

#plot(p, f;  kwargs...) =  qsave(draw(Chart(p; kwargs...)), f)

plot(p, f;  kwargs...) = qsave(draw(plot(input(p); kwargs...)), f)
plot(x::Vector{PointList}; kw...) = Chart(x; kw...)


##############################################################################
# option 4

Chart(x; kw...) = Chart(input(x); kw...)

function Chart(pll::Vector{PointList}; kw...)
    chart = Chart(; pll, allowed_kws(Chart, kw)...)
    axis  = Axis(chart.pll; kw...)
    chart.axis = axis
    return chart
end

##############################################################################

# Axis also takes data, how does it do it
#

function PlotKitCairo.draw(chart::Chart)
    axis = chart.axis
    ad = AxisDrawable(axis)
    drawaxis(ad)
    setclipbox(ad)
    draw(ad, chart)
    return ad
end


# should probably use this instead.
# for (index,value)  in pairs(x); println(index, "  ", Tuple(index)); end
#

function PlotKitCairo.draw(ad::AxisDrawable, chart::Chart)
    for (i, pl) in enumerate(chart.pll)
        drawpll(ad, pl, i, chart)
        # line(ad, pl.points; linestyle = ati(chart.linestyle, i))
        # if ati(chart.markerradius, i) > 0
        #     for p in pl.points
        #         circle(ad, p, ati(chart.markerradius, i);
        #                scaletype = ati(chart.markerscaletype, i), 
        #                fillcolor = ati(chart.markerfillcolor, i), 
        #                linestyle = ati(chart.markerlinestyle, i))
        #     end
        # end
    end
    drawchartlabels(ad, chart)
    return ad
end

function drawpll(ad, pl::PointList, i, (; linestyle, markerradius, markerscaletype, markerfillcolor, markerlinestyle))
    line(ad, pl.points; linestyle=ati(linestyle, i))
    if ati(markerradius, i) > 0
        for p in pl.points
            circle(ad, p, ati(markerradius, i);
                scaletype=ati(markerscaletype, i),
                fillcolor=ati(markerfillcolor, i),
                linestyle=ati(markerlinestyle, i))
        end
    end
end



############################################################

function drawchartlabels(ad::AxisDrawable, chart::Chart)
    if chart.labeled
        drawlabels(ad, chart.pll, chart)
        # xdes = chart.xdes
        # if isnothing(xdes)
        #     xdes = (ad.axis.box.xmax + ad.axis.box.xmin)/2
        # end
        # llp = LineLabelPositioner(ad, chart.pll, xdes; separation = chart.labelseparation)
        # for i = 1:length(chart.pll)
        #     drawlabel(ad, llp.markerpositions[i], i;
        #               labelradius = chart.labelradius,
        #               labelcolor = ati(chart.labelcolor, i),
        #               labeltext = ati(chart.labeltext, i),
        #               fontsize = chart.labelfontsize,
        #               fontname = chart.labelfontname)
        # end
    end
end

function drawlabels(ad, pll, (;xdes, labelseparation, labelradius, 
    labelcolor, labeltext, labelfontsize, labelfontname))
    if isnothing(xdes)
        xdes = (ad.axis.box.xmax + ad.axis.box.xmin)/2
    end
    llp = LineLabelPositioner(ad, pll, xdes; separation = labelseparation)
        for i = 1:length(pll)
            drawlabel(ad, llp.markerpositions[i], i;
                      labelradius = labelradius,
                      labelcolor = ati(labelcolor, i),
                      labeltext = ati(labeltext, i),
                      fontsize = labelfontsize,
                      fontname = labelfontname)
        end

end


function drawlabel(ad::AxisDrawable, p::Point, i;
                   labeltext = string(i),
                   labelcolor = colormap(i),
                   labelradius = 8, fontsize = 9, fontname = "Sans")
    circle(ad.ctx, p, labelradius; 
           linestyle = LineStyle(labelcolor, 1), fillcolor = Color(:white))
    text(ad.ctx, p, fontsize, labelcolor, labeltext,
         fname = fontname, horizontal = "center", vertical = "center")
end

#########################################################################

plot(x::Vector{ChainList}; kw...) = MultiChart(x; kw...)

Base.@kwdef mutable struct MultiChart
    linestyle = i -> LineStyle(colormap(i) , 1)
    markerradius = i -> 0
    markerfillcolor = i -> nothing
    markerlinestyle = i -> nothing
    markerscaletype = i -> :none
    labeled = true
    xdes = nothing
    labelfontname = "Sans"
    labelfontsize = 9
    labelradius = 8
    labeltext = i -> string(i)
    labelcolor = i -> colormap(i)
    labelseparation = 10
    cll::Vector{ChainList}   # chainlist list
    axis = nothing
    labelpositioner = nothing
end


MultiChart(x; kw...) = MultiChart(input(x); kw...)

# returns a vector of PointLists
function flatten_chainlist(cll::Vector{ChainList})
     reduce(vcat, a.chains for a in cll)
end


function MultiChart(cll::Vector{ChainList}; kw...)
    mchart = MultiChart(; cll, allowed_kws(MultiChart, kw)...)
    pll = flatten_chainlist(cll)
    axis  = Axis(pll; kw...)
    mchart.axis = axis
    return mchart
end


function PlotKitCairo.draw(mchart::MultiChart)
    axis = mchart.axis
    ad = AxisDrawable(axis)
    drawaxis(ad)
    setclipbox(ad)
    draw(ad, mchart)
    return ad
end

rightmost(pl::PointList) = maximum(a.x for a in pl.points)
leftmost(pl::PointList) = minimum(a.x for a in pl.points)


"""
    get_biggest_piece(cl::ChainList, xmin, xmax)

Given a chainlist, that is a list of pointlists, overlap each with the [xmin,xmax]
interval and return the pointlist with largest overlap .
"""
function get_biggest_piece(cl::ChainList, xmin, xmax)
    psizes = [min(rightmost(pl), xmax) - max(leftmost(pl), xmin) for pl in cl.chains]
    val, ind = findmax(psizes)
    return cl.chains[ind]
end

function PlotKitCairo.draw(ad::AxisDrawable, mchart::MultiChart)
    xmin = mchart.axis.box.xmin
    xmax = mchart.axis.box.xmax
    biggest_pieces_pll = [get_biggest_piece(cl, xmin, xmax) for cl in mchart.cll]
    for (i, chainlist) in enumerate(mchart.cll)
        chains = chainlist.chains    # a vector{PointList}
        for pl in chains
            drawpll(ad, pl, i, mchart)
        end 
    end
    if mchart.labeled
        drawlabels(ad, biggest_pieces_pll, mchart)
    end 
    return ad
end














##############################################################################
# option 1
#
# if you construct the axis like this, then you cannot put 
# options in the axis construction that depend on the the Chart struct
#
# function Chart(data; kw...)
#     axis  = Axis(data; kw...)
#     return Chart(; data, axis, allowed_kws(Chart, kw)...)
# end
##############################################################################


##############################################################################
# option 2
#
# if you construct the axis like this then you cannot put kw options for axis
# in the call to Chart
#
# PlotKit.Axis(chart::Chart; kw...) = Axis(; merge(axis_defaults(chart), kw)...)
##############################################################################

##############################################################################
# option 3
#
# An issue here is that this constructor
# must have at least one required argument to avoid conflict with
# the constructor defined by @kwdef
#
# Note this needs a kw field in Chart.
#
# Chart(data; kw...) =  Chart(; data, kw, allowed_kws(Chart, kw)...)
#
# Now you can put axis options in the call to Chart
# or in the call to draw
#
# PlotKitAxes.Axis(chart::Chart; kw...) = Axis(chart.data; chart.kw..., kw...)
##############################################################################


##############################################################################
# option 4
#
# 
# function Chart(data; kw...)
#     chart = Chart(; pll = input(data), allowed_kws(Chart, kw)...)
#     axis  = Axis(chart.pll; kw...)
#     chart.axis = axis
#     return chart
# end
# 
#
# This way, options for Axis can be included in the call to Chart.
# And if we need to compute quantities needed for the call
# to Axis, we can do so before the call to Axis.
# But there does need to be a required argument, otherwise
# the base.kw constructor for Chart will be called.
# Another nice feature is that we don't need to store the kw in Chart.
# The call to allowed_kws strips out any keyword arguments
# that the base.kw constructor for Chart cannot accept.
# 



end




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

using PlotKitCairo: Color, LineStyle, PlotKitCairo, Point, PointList, allowed_kws, ati, circle, colormap, draw, input, line, setoptions!, text
using PlotKitAxes: Axis, AxisDrawable, PlotKitAxes, drawaxis, setclipbox

using ..LabelPositioner: LineLabelPositioner

export Chart, drawlabel

Base.@kwdef mutable struct Chart
    linestyle = i -> LineStyle(colormap(i) , 1)
    markerradius = i -> 0
    markerfillcolor = i -> nothing
    markerlinestyle = i -> nothing
    markerscaletype = i -> :none
    labeled = false
    xdes = nothing
    labelfontname = "Sans"
    labelfontsize = 9
    labelradius = 8
    pll::Vector{PointList}   # pointlist list
    axis = nothing
    labelpositioner = nothing
end

    
##############################################################################
# option 4

function Chart(data; kw...)
    chart = Chart(; pll = input(data), allowed_kws(Chart, kw)...)
    axis  = Axis(chart.pll; kw...)
    chart.axis = axis
    return chart
end
##############################################################################

# Axis also takes data, how does it do it
#

function PlotKitCairo.draw(chart::Chart; kw...)
    axis = chart.axis
    ad = AxisDrawable(axis)
    drawaxis(ad)
    setclipbox(ad)
    draw(ad, chart; kw...)
    return ad
end


# should probably use this instead.
# for (index,value)  in pairs(x); println(index, "  ", Tuple(index)); end
#

function PlotKitCairo.draw(ad::AxisDrawable, chart::Chart; kw...)
    for (i, pl) in enumerate(chart.pll)
        #println("points = ", pl.points)
        line(ad, pl.points; linestyle = ati(chart.linestyle, i))
        if ati(chart.markerradius, i) > 0
            for p in pl.points
                circle(ad, p, ati(chart.markerradius, i);
                       scaletype = ati(chart.markerscaletype, i), 
                       fillcolor = ati(chart.markerfillcolor, i), 
                       linestyle = ati(chart.markerlinestyle, i))
            end
        end
    end
    if chart.labeled
        xdes = chart.xdes
        if isnothing(xdes)
            xdes = (ad.axis.box.xmax + ad.axis.box.xmin)/2
        end
        llp = LineLabelPositioner(ad, chart.pll, xdes)
        for i = 1:length(chart.pll)
            drawlabel(ad, llp.markerpositions[i], i;
                      labelradius = chart.labelradius,
                      fontsize = chart.labelfontsize,
                      fontname = chart.labelfontname)
        end
    end
end



function drawlabel(ad::AxisDrawable, p::Point, i; labelradius = 8, fontsize = 9, fontname = "Sans")
    col = colormap(i)
    circle(ad.ctx, p, labelradius; 
           linestyle = LineStyle(col,1), fillcolor = Color(:white))
    text(ad.ctx, p, fontsize, col, string(i);
         fname = fontname, horizontal = "center", vertical = "center")
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




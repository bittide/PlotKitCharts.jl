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

using ..PlotKitAxes: Axis, AxisDrawable, LineStyle, PointList, PlotKitAxes, Point, allowed_kws, circle, colormap, draw, drawaxis, input, line, setclipbox, setoptions!

export Chart

Base.@kwdef mutable struct Chart
    linestyle = i -> LineStyle(colormap(i) , 1)
    markerradius = i -> 0
    markerfillcolor = i -> nothing
    markerlinestyle = i -> nothing
    markerscaletype = i -> :none
    pll::Vector{PointList}   # pointlist list
    axis = nothing
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

function PlotKitAxes.draw(chart::Chart; kw...)
    axis = chart.axis
    ad = AxisDrawable(axis)
    drawaxis(ad)
    setclipbox(ad)
    draw(ad, chart; kw...)
    return ad
end

ati(i, f::Function) = f(i)
ati(i, f) = f

# should probably use this instead.
# for (index,value)  in pairs(x); println(index, "  ", Tuple(index)); end
#

function PlotKitAxes.draw(ad::AxisDrawable, chart::Chart; kw...)
    for (i, pl) in enumerate(chart.pll)
        line(ad, pl.points; linestyle = ati(i, chart.linestyle))
        if ati(i, chart.markerradius) > 0
            for p in pl.points
                circle(ad, p, ati(i, chart.markerradius);
                       scaletype = ati(i, chart.markerscaletype), 
                       fillcolor = ati(i, chart.markerfillcolor), 
                       linestyle = ati(i, chart.markerlinestyle))
            end
        end
    end
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


end




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

module Bars

using ..PlotKitAxes: Axis, AxisDrawable, LineStyle, PlotKitAxes, Point, allowed_kws, circle, colormap, draw, drawaxis, line, rect, setclipbox, setoptions!

export BarChart

Base.@kwdef mutable struct BarChart
    linestyle = i -> LineStyle(colormap(i,2) , 1)
    fillcolor = i -> colormap(i)
    barshrink = 0.9
    data
    axis = nothing
end

    
##############################################################################
# option 4

function BarChart(data; kw...)
    barchart = BarChart(; data, allowed_kws(BarChart, kw)...)
    barwidth = getbarwidth(list_of_series(data)[1])
    axis  = Axis(barchart.data; xdatamargin = barwidth/2, kw...)
    barchart.axis = axis
    return barchart
end
##############################################################################

# Axis also takes data, how does it do it
#
list_of_series(x::Vector{Point}) = [x]
list_of_series(x::Vector{Vector{Point}}) = x
list_of_series(x::Array{Vector{Point}}) = x

function getbarwidth(series)
    xvalues = [a.x for a in series]
    dx = diff(xvalues)
    w = maximum(dx)
    println((;xvalues, dx, w))
    return w
end

function PlotKitAxes.draw(barchart::BarChart; kw...)
    axis = barchart.axis
    ad = AxisDrawable(axis)
    drawaxis(ad)
    setclipbox(ad)
    draw(ad, barchart; kw...)
    return ad
end

ati(i, f::Function) = f(i)
ati(i, f) = f

# should probably use this instead.
# for (index,value)  in pairs(x); println(index, "  ", Tuple(index)); end
#

function PlotKitAxes.draw(ad::AxisDrawable, barchart::BarChart; kw...)
    serieslist = list_of_series(barchart.data)

    series = serieslist[1]
    barwidth = getbarwidth(series)
    hw = barchart.barshrink * (barwidth/2)
    
    for (i,p) in pairs(series)
        linestyle = ati(i, barchart.linestyle)
        fillcolor = ati(i, barchart.fillcolor)

        rect(ad, Point(p.x - hw, 0), Point(2 * hw, p.y);
             fillcolor = ati(i, barchart.fillcolor), 
             linestyle = ati(i, barchart.linestyle))
    end
    
    
end



end




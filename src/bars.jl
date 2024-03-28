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

using ..PlotKitAxes: Axis, AxisDrawable, LineStyle, PlotKitAxes, Point, PointList, allowed_kws, circle, colormap, draw, drawaxis, line, rect, setclipbox, setoptions!

export BarChart

Base.@kwdef mutable struct BarChart
    linestyle = i -> LineStyle(colormap(i,2) , 1)
    fillcolor = i -> colormap(i)
    barshrink = 0.9
    pl::PointList
    axis = nothing
end

    
##############################################################################
# option 4

function BarChart(data; kw...)
    pl = PointList(data)
    barchart = BarChart(; pl, allowed_kws(BarChart, kw)...)
    barwidth = getbarwidth(pl)
    axis  = Axis(pl; xdatamargin = barwidth/2, kw...)
    barchart.axis = axis
    return barchart
end
##############################################################################

function getbarwidth(pl::PointList)
    xvalues = [a.x for a in pl.points]
    dx = diff(xvalues)
    w = maximum(dx)
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

function PlotKitAxes.draw(ad::AxisDrawable, barchart::BarChart; kw...)
    barwidth = getbarwidth(barchart.pl)
    hw = barchart.barshrink * (barwidth/2)
    
    for (i,p) in pairs(barchart.pl.points)
        linestyle = ati(i, barchart.linestyle)
        fillcolor = ati(i, barchart.fillcolor)

        rect(ad, Point(p.x - hw, 0), Point(2 * hw, p.y);
             fillcolor = ati(i, barchart.fillcolor), 
             linestyle = ati(i, barchart.linestyle))
    end
    
    
end



end




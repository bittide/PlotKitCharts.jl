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

using ..PlotKitAxes: Axis, AxisDrawable, LineStyle, PlotKitAxes, Point, circle, colormap, draw, drawaxis, line, setclipbox, setoptions!

export Chart, ChartStyle

Base.@kwdef mutable struct ChartStyle
    linestyle = i -> LineStyle(colormap(i) , 1)
    markerradius = i -> 0
    markerfillcolor = i -> nothing
    markerlinestyle = i -> nothing
    markerscaletype = i -> :none
end


Base.@kwdef mutable struct Chart
    axis::Axis
    data
    cs::ChartStyle
end

list_of_series(x::Vector{Point}) = [x]
list_of_series(x::Vector{Vector{Point}}) = x


function Chart(data; kw...)
    cs = ChartStyle()
    setoptions!(cs, "chartstyle_", kw...)
    axis = Axis(data; kw...)
    return Chart(axis, data, cs)
end

function PlotKitAxes.draw(chart::Chart)
    ad = AxisDrawable(chart.axis)
    cs = chart.cs
    serieslist = list_of_series(chart.data)
    drawaxis(ad)
    setclipbox(ad)
    for (i,series) in enumerate(serieslist)
        line(ad, series; linestyle = cs.linestyle(i))
        if cs.markerradius(i) > 0
            for p in series[i]
                circle(ad, p, cs.markerradius(i);
                       scaletype = cs.markerscaletype(i),
                       fillcolor = cs.markerfillcolor(i),
                       linestyle = cs.markerlinestyle(i))
            end
        end
    end
    return ad
end


end




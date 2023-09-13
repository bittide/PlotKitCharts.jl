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

using ..PlotKitAxes: Axis, AxisDrawable, LineStyle, PlotKitAxes, Point, allowed_kws, circle, colormap, draw, drawaxis, line, setclipbox, setoptions!

export Chart

Base.@kwdef mutable struct Chart
    linestyle = i -> LineStyle(colormap(i) , 1)
    markerradius = i -> 0
    markerfillcolor = i -> nothing
    markerlinestyle = i -> nothing
    markerscaletype = i -> :none
    data
    kw = Dict()
end

    


# if you construct the axis like this, then you cannot put 
# options in the axis construction that depend on the the Chart struct
#
# function Chart(data; kw...)
#     axis  = Axis(data; kw...)
#     return Chart(; data, axis, allowed_kws(Chart, kw)...)
# end


# if you construct the axis like this then you cannot put kw options for axis
# in the call to Chart
#
# PlotKit.Axis(chart::Chart; kw...) = Axis(; merge(axis_defaults(chart), kw)...)


# So instead we do this. An issue here is that this constructor
# must have at least one required argument to avoid conflict with
# the constructor defined by @kwdef
Chart(data; kw...) =  Chart(; data, kw, allowed_kws(Chart, kw)...)


# Now you can put axis options in the call to Chart
# or in the call to draw
PlotKitAxes.Axis(chart::Chart; kw...) = Axis(chart.data; chart.kw..., kw...)


list_of_series(x::Vector{Point}) = [x]
list_of_series(x::Vector{Vector{Point}}) = x

function PlotKitAxes.draw(chart::Chart; kw...)
    axis = Axis(chart; kw...)
    ad = AxisDrawable(axis)
    serieslist = list_of_series(chart.data)
    drawaxis(ad)
    setclipbox(ad)
    for (i,series) in enumerate(serieslist)
        line(ad, series; linestyle = chart.linestyle(i))
        if chart.markerradius(i) > 0
            for p in series[i]
                circle(ad, p, chart.markerradius(i);
                       scaletype = chart.markerscaletype(i),
                       fillcolor = chart.markerfillcolor(i),
                       linestyle = chart.markerlinestyle(i))
            end
        end
    end
    return ad
end


end




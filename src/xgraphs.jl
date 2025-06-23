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


module Xgraphs

export XGraph, inputgraph, plot

import ..Charts: Charts, plot

using JuliaTools
using PlotKitAxes: PlotKitAxes, Axis, AxisDrawable, drawaxis, setclipbox
using PlotKitCairo: PlotKitCairo, Color, LineStyle, Point, PointList, VertexPairs,
    circle, colormap, corners, draw, expand_box, input, line, qsave,
    smallest_box_containing_data, text
using PlotKitDiagrams: CurvedPath, Graph, Node, Path, StraightPath, TriangularArrow

Base.@kwdef mutable struct XGraph
    data::VertexPairs
    pkgraph = nothing
    axis = nothing
    directed = true
    nodelabels = string
    nodecolors = colormap(3)
    nodefontsize = 0.15
    nodefontname = "Sans"
    noderadius = 0.2
    nodelinestyle = LineStyle(Color(:black), 1)
    nodetextcolor = Color(:white)
    edgelabels = string
    edgelabelpos = e -> 0.5
    edgelabelfontsize = e -> 0.12
    edgelabelfontname = e -> "Sans"
    edgelabelradius = e -> 0.14
    edgelabelfillcolor = e -> Color(:white)
    edgelabeltextcolor = e -> colormap(1)
    edgelabeloffset = e -> nothing
    edgecurved = e -> false
    edgecurveparam = e -> 0.3
    edgetheta1 = e -> -pi/6
    edgetheta2 = e -> -pi/6
    linestyles = e -> LineStyle(Color(:black), 3)
    arrowcolors = e -> Color(:black)
    arrowposnolabel = e -> 0.5
    arrowposlabel = e -> 0.8
    arrowcenter = e -> false
    arrowsize = e -> 0.15
    classes = []
    classmargin = 0.4
    extraedgelabelnodes = e -> ()
    scaletype = :x
    drawbody = true
end


# convenience function
Charts.plotselector(x::VertexPairs; kw...) = XGraph(x; kw...)

XGraph(x; kw...) = XGraph(input(x); kw...)

function XGraph(data::VertexPairs; kw...)
    xg = XGraph(; data, allowed_kws(XGraph, kw)...)
    xg.pkgraph = make_pkgraph(xg::XGraph; kw...)
    xg.axis = xg.pkgraph.axis
    return xg
end

function PlotKitCairo.draw(xg::XGraph)
    axis = xg.axis
    ad = AxisDrawable(axis)
    drawaxis(ad)
    setclipbox(ad)
    if xg.drawbody
        draw(ad, xg)
    end
    return ad
end

function PlotKitCairo.draw(ad::AxisDrawable, xg::XGraph)
    draw(ad, xg.pkgraph)
    return ad
end


function make_pkgraph(xg::XGraph; kw...)
    x = xg.data.layout
    edges = xg.data.edges
    n = length(x)
    m = length(edges)
    function has_both_edges(e)
        r = (src = edges[e].dst, dst = edges[e].src)
        return r in edges
    end

    nodepoint(nodeid) = x[nodeid]
    nodes_to_bbox_corners(nodeids) = corners(
        expand_box(smallest_box_containing_data(
            PointList( [a for a in nodepoint.(nodeids)] )),
                   xg.classmargin,  xg.classmargin))

    makeclass(cls) = StraightPath(; points = nodes_to_bbox_corners(cls.nodeids),
                                  closed = true, linestyle = nothing,
                                  fillcolor = cls.fillcolor)
    graph_extras = makeclass.(xg.classes)

    graph_nodes = [Node(; text = string(ati(xg.nodelabels,i)),
                        fontsize = ati(xg.nodefontsize,i),
                        fontname = ati(xg.nodefontname,i),
                        radius = ati(xg.noderadius,i),
                        linestyle = ati(xg.nodelinestyle, i),
                        textcolor = ati(xg.nodetextcolor, i),
                        scaletype = xg.scaletype,
                        fillcolor = ati(xg.nodecolors,i)) for i=1:n]

    edge_label_nodes(e) = (ati(xg.edgelabelpos,e),
                           Node(fontsize = ati(xg.edgelabelfontsize,e),
                                fontname = ati(xg.edgelabelfontname,e),
                                radius = ati(xg.edgelabelradius,e),
                                fillcolor = ati(xg.edgelabelfillcolor,e),
                                textcolor = ati(xg.edgelabeltextcolor,e),
                                offset = ati(xg.edgelabeloffset,e),
                                linestyle = nothing,
                                text = string(ati(xg.edgelabels,e))))

    function path(e)
        arr = TriangularArrow(size = ati(xg.arrowsize,e),
                              fillcolor = ati(xg.arrowcolors,e),
                              center = ati(xg.arrowcenter,e)
                              )
        if ati(xg.edgelabels,e) == ""
            nodes = (ati(xg.extraedgelabelnodes,e)...,)
            arrows = ((ati(xg.arrowposnolabel,e), arr), )
        else
            nodes = (ati(xg.extraedgelabelnodes,e)..., edge_label_nodes(e),)
            arrows = ((ati(xg.arrowposlabel,e), arr), )
        end

        if !xg.directed
            if ati(xg.edgecurved,e)
                return CurvedPath(; nodes, linestyle = ati(xg.linestyles,e),
                                  curveparam = ati(xg.edgecurveparam,e),
                                  theta1 = ati(xg.edgetheta1,e),
                                  theta2 = ati(xg.edgetheta2,e)
                                  )
            end
            # no arrows, straight paths
            if has_both_edges(e)
                # only draw one of the two edges
                if edges[e].src < edges[e].dst
                    return Path(; nodes, linestyle = ati(xg.linestyles,e))
                else
                    return Path(; nodes, linestyle = nothing)
                end
            else
                return Path(; nodes, linestyle = ati(xg.linestyles,e))
            end
        end

        if has_both_edges(e) || ati(xg.edgecurved,e)
            return CurvedPath(; arrows, nodes, linestyle = ati(xg.linestyles,e),
                              curveparam = ati(xg.edgecurveparam,e),
                              theta1 = ati(xg.edgetheta1,e),
                              theta2 = ati(xg.edgetheta2,e)
                              )
        end
        return Path(; arrows, nodes, linestyle = ati(xg.linestyles,e))
    end
    graph_paths = [ path(e) for e=1:m]
    pkgr = Graph(xg.data;
        extras = graph_extras,
        nodes = graph_nodes,
        paths = graph_paths, kw...)
    return pkgr
end














end


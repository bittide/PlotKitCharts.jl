
module Xgraphs

export XGraphStyle, XGraph, inputgraph, plot

using PlotKitCairo: Color, LineStyle, PlotKitCairo, Point, PointList, VertexPairs, ati, circle, colormap, corners, draw, expand_box, line, qsave,  text, setoptions!, smallest_box_containing_data, input

import ..Charts: Charts, plot

using PlotKitDiagrams: CurvedPath, Graph, Node, Path, StraightPath, TriangularArrow

Base.@kwdef mutable struct XGraphStyle
    directed = true
    nodelabels = string
    nodecolors = i -> colormap(3)
    nodefontsize = i -> 0.15
    nodefontname = i -> "Sans"
    noderadius = i -> 0.2
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
    linestyles = e -> LineStyle(Color(:black), 1)
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
    gs = XGraphStyle()
    setoptions!(gs, "", kw...)
    return XGraph(gs, data.edges, data.layout; kw...)
end


#function XGraph(edges::Vector{@NamedTuple{src::Int64, dst::Int64}}, x::Vector{Point}; kw...)
#    gs = XGraphStyle()
#    setoptions!(gs, "", kw...)
#    return XGraph(gs, edges, x; kw...)
#end

#
# We don't have a way of drawing an XGraph on an existing axisdrawable.
#
#
function XGraph(xgs::XGraphStyle, edges, x; kw...)
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
                   xgs.classmargin,  xgs.classmargin))

    makeclass(cls) = StraightPath(; points = nodes_to_bbox_corners(cls.nodeids),
                                  closed = true, linestyle = nothing,
                                  fillcolor = cls.fillcolor)
    graph_extras = makeclass.(xgs.classes)

    graph_nodes = [Node(; text = string(ati(xgs.nodelabels,i)),
                        fontsize = ati(xgs.nodefontsize,i),
                        fontname = ati(xgs.nodefontname,i),
                        radius = ati(xgs.noderadius,i),
                        scaletype = xgs.scaletype,
                        fillcolor = ati(xgs.nodecolors,i)) for i=1:n]

    edge_label_nodes(e) = (ati(xgs.edgelabelpos,e),
                           Node(fontsize = ati(xgs.edgelabelfontsize,e),
                                fontname = ati(xgs.edgelabelfontname,e),
                                radius = ati(xgs.edgelabelradius,e),
                                fillcolor = ati(xgs.edgelabelfillcolor,e),
                                textcolor = ati(xgs.edgelabeltextcolor,e),
                                offset = ati(xgs.edgelabeloffset,e),
                                linestyle = nothing,
                                text = string(ati(xgs.edgelabels,e))))

    function path(e)
        arr = TriangularArrow(size = ati(xgs.arrowsize,e),
                              fillcolor = ati(xgs.arrowcolors,e),
                              center = ati(xgs.arrowcenter,e)
                              )
        if ati(xgs.edgelabels,e) == ""
            nodes = (ati(xgs.extraedgelabelnodes,e)...,)
            arrows = ((ati(xgs.arrowposnolabel,e), arr), )
        else
            nodes = (ati(xgs.extraedgelabelnodes,e)..., edge_label_nodes(e),)
            arrows = ((ati(xgs.arrowposlabel,e), arr), )
        end

        if !xgs.directed
            if ati(xgs.edgecurved,e)
                return CurvedPath(; nodes, linestyle = ati(xgs.linestyles,e),
                                  curveparam = ati(xgs.edgecurveparam,e),
                                  theta1 = ati(xgs.edgetheta1,e),
                                  theta2 = ati(xgs.edgetheta2,e)
                                  )
            end
            # no arrows, straight paths
            if has_both_edges(e)
                # only draw one of the two edges
                if edges[e].src < edges[e].dst
                    return Path(; nodes, linestyle = ati(xgs.linestyles,e))
                else
                    return Path(; nodes, linestyle = nothing)
                end
            else
                return Path(; nodes, linestyle = ati(xgs.linestyles,e))
            end
        end

        if has_both_edges(e) || ati(xgs.edgecurved,e)
            return CurvedPath(; arrows, nodes, linestyle = ati(xgs.linestyles,e),
                              curveparam = ati(xgs.edgecurveparam,e),
                              theta1 = ati(xgs.edgetheta1,e),
                              theta2 = ati(xgs.edgetheta2,e)
                              )
        end
        return Path(; arrows, nodes, linestyle = ati(xgs.linestyles,e))
    end
    graph_paths = [ path(e) for e=1:m]
    pkgr = Graph(edges, x; graph_extras, graph_nodes, graph_paths, drawbody = xgs.drawbody, kw...)
    return pkgr
end














end



module Xgraphs

export XGraphStyle, XGraph

using PlotKitCairo: Color, LineStyle, PlotKitCairo, Point, PointList, ati, circle, colormap, corners, draw, expand_box, line, text, setoptions!, smallest_box_containing_data


using PlotKitDiagrams: CurvedPath, Graph, Node, Path, StraightPath, TriangularArrow

Base.@kwdef mutable struct XGraphStyle
    directed = true
    nodelabels = i -> ""
    nodecolors = i -> colormap(3)
    nodefontsize = i -> 0.15
    nodefontname = i -> "Sans"
    noderadius = i -> 0.2    
    edgelabels = e -> ""
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
end

function XGraph(edges, x; kw...)
    gs = XGraphStyle()
    setoptions!(gs, "", kw...)
    return XGraph(gs, edges, x; kw...)
end


function XGraph(gs::XGraphStyle, edges, x; kw...)
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
                   gs.classmargin,  gs.classmargin))

    makeclass(cls) = StraightPath(; points = nodes_to_bbox_corners(cls.nodeids),
                                  closed = true, linestyle = nothing,
                                  fillcolor = cls.fillcolor)
    graph_extras = makeclass.(gs.classes)

    graph_nodes = [Node(; text = string(ati(gs.nodelabels,i)),
                        fontsize = ati(gs.nodefontsize,i),
                        fontname = ati(gs.nodefontname,i),
                        radius = ati(gs.noderadius,i),
                        scaletype = gs.scaletype,
                        fillcolor = ati(gs.nodecolors,i)) for i=1:n]

    edge_label_nodes(e) = (ati(gs.edgelabelpos,e),
                           Node(fontsize = ati(gs.edgelabelfontsize,e),
                                fontname = ati(gs.edgelabelfontname,e),
                                radius = ati(gs.edgelabelradius,e),
                                fillcolor = ati(gs.edgelabelfillcolor,e),
                                textcolor = ati(gs.edgelabeltextcolor,e),
                                offset = ati(gs.edgelabeloffset,e),
                                linestyle = nothing,
                                text = string(ati(gs.edgelabels,e))))

    function path(e)
        arr = TriangularArrow(size = ati(gs.arrowsize,e),
                              fillcolor = ati(gs.arrowcolors,e),
                              center = ati(gs.arrowcenter,e)
                              )
        if ati(gs.edgelabels,e) == ""
            nodes = (ati(gs.extraedgelabelnodes,e)...,)
            arrows = ((ati(gs.arrowposnolabel,e), arr), )
        else
            nodes = (ati(gs.extraedgelabelnodes,e)..., edge_label_nodes(e),)
            arrows = ((ati(gs.arrowposlabel,e), arr), )
        end
        
        if !gs.directed
            if ati(gs.edgecurved,e)
                return CurvedPath(; nodes, linestyle = ati(gs.linestyles,e),
                                  curveparam = ati(gs.edgecurveparam,e),
                                  theta1 = ati(gs.edgetheta1,e),
                                  theta2 = ati(gs.edgetheta2,e)
                                  )
            end
            # no arrows, straight paths
            if has_both_edges(e)
                # only draw one of the two edges
                if edges[e].src < edges[e].dst
                    return Path(; nodes, linestyle = ati(gs.linestyles,e))
                else
                    return Path(; nodes, linestyle = nothing)
                end
            else
                return Path(; nodes, linestyle = ati(gs.linestyles,e))
            end
        end

        if has_both_edges(e) || ati(gs.edgecurved,e)
            return CurvedPath(; arrows, nodes, linestyle = ati(gs.linestyles,e),
                              curveparam = ati(gs.edgecurveparam,e),
                              theta1 = ati(gs.edgetheta1,e),
                              theta2 = ati(gs.edgetheta2,e)
                              )
        end
        return Path(; arrows, nodes, linestyle = ati(gs.linestyles,e))
    end
    graph_paths = [ path(e) for e=1:m]
    pkgr = Graph(edges, x; graph_extras, graph_nodes, graph_paths, kw...)
    return pkgr
end














end


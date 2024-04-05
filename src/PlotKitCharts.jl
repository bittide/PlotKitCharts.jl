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

module PlotKitCharts

include("labelpositioner.jl")
using .LabelPositioner

include("charts.jl")
using .Charts

include("bars.jl")
using .Bars

include("xgraphs.jl")
using .Xgraphs

#include("digraph.jl")
#using .DiGraph

##############################################################################
function reexport(m)
    for a in names(m)
        eval(Expr(:export, a))
    end
end

reexport(LabelPositioner)
reexport(Charts)
reexport(Bars)
reexport(Xgraphs)


#reexport(DiGraph)




end




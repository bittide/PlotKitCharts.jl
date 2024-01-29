
#
# run using Pkg.test("PlotKitCharts")
#
#
# or using
#
#  cd PlotKitCharts.jl/test
#  julia
#  include("runtests.jl")
#
#
#

module Runtests
using PlotKitCairo
using PlotKitAxes
using PlotKitCharts
using Test
include("testset.jl")
end

using .Runtests
Runtests.main()



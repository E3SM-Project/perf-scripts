using CSV
using Printf
using Plots

const PEAK_FP64_FLOPS = 26.5E12::Float64 # 1 GCN
const PEAK_FP32_FLOPS = 26.5E12::Float64
const PEAK_BW         = 1.6E12::Float64 # TB/s 1 GCN
const TITLESIZE = 12
const TEXTSIZE = 8
const kernelName = "void Kokkos::Experimental::Impl::hip_parallel_launch_constant_memory<Kokkos::Impl::ParallelFor<scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::p3_main(scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::P3PrognosticState const&, scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::P3DiagnosticInputs const&, scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::P3DiagnosticOutputs const&, scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::P3Infrastructure const&, scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::P3HistoryOnly const&, scream::p3::Functions<double, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> >::P3LookupTables const&, ekat::WorkspaceManager<ekat::Pack<double, 1>, Kokkos::Device<Kokkos::Experimental::HIP, Kokkos::Experimental::HIPSpace> > const&, int, int)::{lambda(Kokkos::Impl::HIPTeamMember const&)#1}, Kokkos::TeamPolicy<Kokkos::Experimental::HIP>, Kokkos::Experimental::HIP> >() [clone .kd]"

# The input CSV has following columns
# KernelName,Etime,Etime share,FP32_FLOPS,FP64_FLOPS,FP32_FLOPS_PER_SEC,FP64_FLOPS_PER_SEC,Bytes_Write,Bytes_Read,FP32_AI,FP64_AI


function main()

    fp32_flops = Vector{Tuple{Float64, Float64}}()
    fp64_flops = Vector{Tuple{Float64, Float64}}()
    fp32_ai = Vector{Tuple{Float64, Float64}}()
    fp64_ai = Vector{Tuple{Float64, Float64}}()

    p3_fp32_flops = Vector{Tuple{Float64, Float64}}()
    p3_fp64_flops = Vector{Tuple{Float64, Float64}}()
    p3_fp32_ai = Vector{Tuple{Float64, Float64}}()
    p3_fp64_ai = Vector{Tuple{Float64, Float64}}()

    num_kernel_launches = 0
    
    for row in CSV.File(ARGS[1])

        num_kernel_launches += 1

        try
            if !(row.FP32_FLOPS_PER_SEC isa Missing) && (row.FP32_FLOPS_PER_SEC != 0.0)
                push!(fp32_flops, (row.Etime, row.FP32_FLOPS_PER_SEC))
                push!(fp32_ai, (row.Etime, row.FP32_AI))
                if startswith(row.KernelName, kernelName)
                    push!(p3_fp32_flops, (row.Etime, row.FP32_FLOPS_PER_SEC))
                    push!(p3_fp32_ai, (row.Etime, row.FP32_AI))
                end
            end

            if !(row.FP64_FLOPS_PER_SEC isa Missing) && (row.FP64_FLOPS_PER_SEC != 0.0)
                push!(fp64_flops, (row.Etime, row.FP64_FLOPS_PER_SEC))
                push!(fp64_ai, (row.Etime, row.FP64_AI))
                if startswith(row.KernelName, kernelName)
                    push!(p3_fp64_flops, (row.Etime, row.FP64_FLOPS_PER_SEC))
                    push!(p3_fp64_ai, (row.Etime, row.FP64_AI))
                end
            end
        catch e
            println("ERROR at line ", (string(e)))
        end
    end

    println("")
    println("Total # of kernel launches: ", num_kernel_launches)
    println("Total # of fp32 kernel launches: ", length(fp32_flops))
    println("Total # of fp64 kernel launches: ", length(fp64_flops))
    println("Total # of p3 fp32 kernel launches: ", length(p3_fp32_flops))
    println("Total # of p3 fp64 kernel launches: ", length(p3_fp64_flops))

    println("")
    @printf("Theoretical Peak FP32 FLOPS (1 GCN) %.2e\n", PEAK_FP32_FLOPS)
    @printf("Theoretical Peak FP64 FLOPS (1 GCN) %.2e\n", PEAK_FP64_FLOPS)
    @printf("Theoretical Peak HBM Bandwidth (1 GCN) %.2e\n", PEAK_BW)
    println("")

    sum_fp32_flops = [0.0, 0.0] # sum etime, sum of etime * value
    for (etime, value) in fp32_flops
        sum_fp32_flops[1] += etime
        sum_fp32_flops[2] += etime * value
    end

    sum_fp64_flops = [0.0, 0.0] # sum etime, sum of etime * value
    for (etime, value) in fp64_flops
        sum_fp64_flops[1] += etime
        sum_fp64_flops[2] += etime * value
    end

    sum_fp32_ai = [0.0, 0.0]
    for (etime, value) in fp32_ai
        sum_fp32_ai[1] += etime
        sum_fp32_ai[2] += etime * value
    end

    sum_fp64_ai = [0.0, 0.0] # sum etime, sum of etime * value
    for (etime, value) in fp64_ai
        sum_fp64_ai[1] += etime
        sum_fp64_ai[2] += etime * value
    end

    sum_p3_fp32_flops = [0.0, 0.0] # sum etime, sum of etime * value
    for (etime, value) in p3_fp32_flops
        sum_p3_fp32_flops[1] += etime
        sum_p3_fp32_flops[2] += etime * value
    end

    sum_p3_fp64_flops = [0.0, 0.0] # sum etime, sum of etime * value
    for (etime, value) in p3_fp64_flops
        sum_p3_fp64_flops[1] += etime
        sum_p3_fp64_flops[2] += etime * value
    end

    sum_p3_fp32_ai = [0.0, 0.0]
    for (etime, value) in p3_fp32_ai
        sum_p3_fp32_ai[1] += etime
        sum_p3_fp32_ai[2] += etime * value
    end

    sum_p3_fp64_ai = [0.0, 0.0] # sum etime, sum of etime * value
    for (etime, value) in p3_fp64_ai
        sum_p3_fp64_ai[1] += etime
        sum_p3_fp64_ai[2] += etime * value
    end

    avg_fp32_flops = sum_fp32_flops[2] / sum_fp32_flops[1]
    avg_fp64_flops = sum_fp64_flops[2] / sum_fp64_flops[1]
    avg_fp32_ai    = sum_fp32_ai[2] / sum_fp32_ai[1]
    avg_fp64_ai    = sum_fp64_ai[2] / sum_fp64_ai[1]

    avg_p3_fp32_flops = sum_p3_fp32_flops[2] / sum_p3_fp32_flops[1]
    avg_p3_fp64_flops = sum_p3_fp64_flops[2] / sum_p3_fp64_flops[1]
    avg_p3_fp32_ai    = sum_p3_fp32_ai[2] / sum_p3_fp32_ai[1]
    avg_p3_fp64_ai    = sum_p3_fp64_ai[2] / sum_p3_fp64_ai[1]

    # all rows
    total_time = sum_fp64_flops[1] + sum_fp32_flops[1]

    @printf("percentage fp32 kernel elapsed time: %.1f %%\n", sum_fp32_flops[1]/total_time*100.)
    @printf("percentage fp64 kernel elapsed time: %.1f %%\n", sum_fp64_flops[1]/total_time*100.)
    println("")

    @printf("Time-weighted average fp32 flops: %.2e, %.2f %% of Peak FP32\n",
        avg_fp32_flops, avg_fp32_flops/PEAK_FP32_FLOPS*100.)
    @printf("Time-weighted average fp64 flops: %.2e, %.2f %% of Peak FP64\n",
        avg_fp64_flops, avg_fp64_flops/PEAK_FP64_FLOPS*100.)
    @printf("Time-weighted average fp32 arithmetic intensity: %.2f\n", avg_fp32_ai)
    @printf("Time-weighted average fp64 arithmetic intensity: %.2f\n", avg_fp64_ai)

    cpoint = PEAK_FP64_FLOPS / PEAK_BW

    xdata = [0.01, 0.1, 1.0, 10.0, 100.0]
    push!(xdata, cpoint)
    sort!(xdata)
    ydata = map(x -> min(PEAK_BW*x, PEAK_FP64_FLOPS), xdata)

    #Plots.pyplot()
    gr()

    plot(xdata, ydata, xaxis=:log, yaxis=:log, legend=:topleft,
    labels="Theoretical peak", xticks=(xdata, ["0.01", "0.1", "1", "10", "", "100"]))

    plot!([avg_fp32_ai], [avg_fp32_flops],
            seriestype = :scatter, xaxis=:log, yaxis=:log,
            labels="FP32 All", markersize=5, c=:white)

    fp32str = @sprintf("(%.2f, %.2e)", avg_fp32_ai, avg_fp32_flops)
    annotate!(avg_fp32_ai, avg_fp32_flops*1.4, text(fp32str, pointsize=TEXTSIZE))

    plot!([avg_fp64_ai], [avg_fp64_flops],
            seriestype = :scatter, xaxis=:log, yaxis=:log,
            labels="FP64 All", markersize=5, c=:black)

    fp64str = @sprintf("(%.2f, %.2e)", avg_fp64_ai, avg_fp64_flops)
    annotate!(avg_fp64_ai, avg_fp64_flops*1.4, text(fp64str, pointsize=TEXTSIZE))

    # p3 rows
    @printf("Time-weighted average p3_fp32 flops: %.2e, %.2f %% of Peak FP32\n",
        avg_p3_fp32_flops, avg_p3_fp32_flops/PEAK_FP32_FLOPS*100.)
    @printf("Time-weighted average p3_fp64 flops: %.2e, %.2f %% of Peak FP64\n",
        avg_p3_fp64_flops, avg_p3_fp64_flops/PEAK_FP64_FLOPS*100.)
    @printf("Time-weighted average p3_fp32 arithmetic intensity: %.2f\n", avg_p3_fp32_ai)
    @printf("Time-weighted average p3_fp64 arithmetic intensity: %.2f\n", avg_p3_fp64_ai)
    println("")

    plot!([avg_p3_fp32_ai], [avg_p3_fp32_flops],
            seriestype = :scatter, xaxis=:log, yaxis=:log,
            labels="P3_FP32", markersize=5, c=:blue)

    p3_fp32str = @sprintf("(%.2f, %.2e)", avg_p3_fp32_ai, avg_p3_fp32_flops)
    annotate!(avg_p3_fp32_ai, avg_p3_fp32_flops*1.4, text(p3_fp32str, pointsize=TEXTSIZE))

    plot!([avg_p3_fp64_ai], [avg_p3_fp64_flops],
            seriestype = :scatter, xaxis=:log, yaxis=:log,
            labels="P3_FP64", markersize=5, c=:red)

    p3_fp64str = @sprintf("(%.2f, %.2e)", avg_p3_fp64_ai, avg_p3_fp64_flops)
    annotate!(avg_p3_fp64_ai, avg_p3_fp64_flops*1.4, text(p3_fp64str, pointsize=TEXTSIZE))

    title!("Roofline Plot - P3 CPP2D, AMD MI250X(1 GCN), 32x1x50", titlefontsize=TITLESIZE)
    xlabel!("Arithmetic Intensity")
    ylabel!("FLOPS")

    peakstr = @sprintf("(%.2f, %.2e)", cpoint, PEAK_FP64_FLOPS)
    annotate!(cpoint, PEAK_FP64_FLOPS*0.7, text(peakstr, pointsize=TEXTSIZE))

    savefig("roofline.pdf")
    savefig("roofline.png")
end

main()

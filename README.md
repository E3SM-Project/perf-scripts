# perf-scripts
Misc scripts for performance data collection and analysis


## genplot.jl 

This is a Julia script to generate a roofline plot from rocprof profiling data

To use the script, three Julia packages should be available: CSV, Plots, and PyPlot.

Next, generate rocprof profiling data with your application as explained here (https://docs.olcf.ornl.gov/systems/crusher_quick_start_guide.html#roofline-profiling)

The script expects a CSV file that has following columns. You can find the formula that generate following data at the link above.
```
    KernelName : kernel name
    Etime : average kernel launch time
    FP32_FLOPS_PER_SEC : average FP32 FLOPs per second
    FP64_FLOPS_PER_SEC : average FP64 FLOPs per second
    FP32_AI : average FP32 arithmetic intensity
    FP64_AI : average PF64 arithmetic intensity
```
In the julia script, "P3Name" variable is used to generate a data point for a particular kernel in the generate roofline plot. You may need to change it with your kernel name.

Finally, run the script.

   `julia ./genplot.jl my_output.csv`

Once completed successful, the script will generate "roofline.pdf" and "roofline.png" images.


CSV := roofline_1st.csv

plot:
	julia --project genplot.jl ${CSV}

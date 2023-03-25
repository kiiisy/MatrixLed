# RTL directory
TOP_MODULE=top_sim
OUT_FILE=scenario.out

# compile
iverilog -g2012  \
    -o ${OUT_FILE} \
    -s ${TOP_MODULE} ./scenario.sv ../src/top.sv ../src/gowin_rpll/gowin_rpll.v ../../simlib/gw1n/prim_sim.v \
    ../src/matrix_core.sv ../src/matrix_top.sv ../src/matrix_pg.sv

# simulation
vvp ${OUT_FILE}
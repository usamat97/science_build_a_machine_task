VERILATOR   = verilator
YOSYS       = yosys
TOP_MODULE  = accelerator

# Candidate: add your .sv files here or use the wildcard.
# Testbench files (*_tb.sv, *_test.sv) are excluded automatically.
SV_SOURCES := $(filter-out %_tb.sv %_test.sv, $(wildcard *.sv))

.PHONY: sw hw synth verify score clean

# -- Software baseline --
# Candidate: replace this with your build + run command.
# Use whatever language and flags you want.
# Must print: SW_OPS_PER_SEC=<float>
sw:
	g++ -O3 -std=c++17 -Wall -Wextra fir_sw.cpp -o fir_sw
	./fir_sw | tee sw_metrics.txt

# -- Hardware accelerator --
# Candidate: replace this with your Verilator build + run command.
# Must print: HW_OPS_PER_SEC=<float>
hw:
	$(VERILATOR) --binary -sv --top-module fir_hw_tb accelerator.sv fir_hw.sv fir_hw_tb.sv
	./obj_dir/Vfir_hw_tb | tee hw_metrics.txt

# -- Synthesis area check (Lattice ECP5 LFE5U-85F) --
SLICE_LIMIT = 10000
DSP_LIMIT  = 156
BRAM_LIMIT = 208

synth: $(SV_SOURCES)
	@echo "read_verilog -sv $(SV_SOURCES)" > _synth_gen.ys
	@echo "hierarchy -check -top $(TOP_MODULE)" >> _synth_gen.ys
	@echo "proc; flatten; opt" >> _synth_gen.ys
	@echo "synth_ecp5 -top $(TOP_MODULE) -json synth.json" >> _synth_gen.ys
	@echo "tee -o utilization.json stat -json" >> _synth_gen.ys
	$(YOSYS) -s _synth_gen.ys -l synth.log -q
	@rm -f _synth_gen.ys
	@python3 -c "\
import json, sys; \
data = json.load(open('utilization.json')); \
mods = data.get('modules', {}); \
top = mods.get('$(TOP_MODULE)', mods.get('\\\\$(TOP_MODULE)', {})); \
cells = top.get('num_cells_by_type', {}); \
slices = cells.get('TRELLIS_SLICE', 0); \
dsps = cells.get('MULT18X18D', 0); \
brams = cells.get('DP16KD', 0); \
print('Slices (TRELLIS_SLICE): %d / $(SLICE_LIMIT)  (~%d LUT4s)' % (slices, slices * 2)); \
print('DSPs (MULT18X18D):      %d / $(DSP_LIMIT)' % dsps); \
print('BRAMs (DP16KD):         %d / $(BRAM_LIMIT)' % brams); \
ok = slices <= $(SLICE_LIMIT) and dsps <= $(DSP_LIMIT) and brams <= $(BRAM_LIMIT); \
print('SYNTH: %s' % ('PASS' if ok else 'FAIL')); \
sys.exit(0 if ok else 1)"

# -- Verify hardware matches software --
# Candidate: replace this with your verification approach.
verify:
# 	diff -u sw_output.txt hw_output.txt | head -40
	cmp -s sw_output.txt hw_output.txt
	@echo "VERIFY: PASS"

# -- Full score --
score: sw hw verify
	@echo ""
	@echo "--- Scoring ---"
	@python3 -c "\
import re; \
sw_txt=open('sw_metrics.txt').read(); \
hw_txt=open('hw_metrics.txt').read(); \
sw=float(re.search(r'SW_OPS_PER_SEC=([0-9.]+)', sw_txt).group(1)); \
hw=float(re.search(r'HW_OPS_PER_SEC=([0-9.]+)', hw_txt).group(1)); \
print('SW_OPS_PER_SEC=%.2f' % sw); \
print('HW_OPS_PER_SEC=%.2f' % hw); \
print('SPEEDUP=%.4fx' % (hw/sw));"

clean:
	rm -rf obj_dir/ synth.json synth.log utilization.json _synth_gen.ys fir_sw sw_output.txt hw_output.txt

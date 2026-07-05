VERILATOR   = verilator
YOSYS       = yosys
TOP_MODULE  = accelerator

HW_SRC_DIR  = hw/src
HW_OUT_DIR  = hw/output
SW_SRC_DIR  = sw/src
SW_OUT_DIR  = sw/output
SYNTH_DIR   = synthesis
SIM_DIR     = sim

# Candidate: add your .sv files here or use the wildcard.
# Testbench files (*_tb.sv, *_test.sv) are excluded automatically.
SV_SOURCES := $(filter-out %_tb.sv %_test.sv, $(wildcard $(HW_SRC_DIR)/*.sv))

.PHONY: sw hw synth verify score clean

# -- Software baseline --
# Must print: SW_OPS_PER_SEC=<float>
sw:
	mkdir -p $(SW_OUT_DIR)
	g++ -O3 -std=c++17 -Wall -Wextra $(SW_SRC_DIR)/fir_sw.cpp -o $(SW_OUT_DIR)/fir_sw
	./$(SW_OUT_DIR)/fir_sw | tee $(SW_OUT_DIR)/sw_metrics.txt

# -- Hardware accelerator --
# Must print: HW_OPS_PER_SEC=<float>
hw:
	mkdir -p $(HW_OUT_DIR)
	$(VERILATOR) --binary -sv --Mdir $(SIM_DIR) --top-module fir_hw_tb $(HW_SRC_DIR)/accelerator.sv $(HW_SRC_DIR)/fir_hw.sv $(HW_SRC_DIR)/fir_hw_tb.sv
	./$(SIM_DIR)/Vfir_hw_tb | tee $(HW_OUT_DIR)/hw_metrics.txt

# -- Synthesis area check (Lattice ECP5 LFE5U-85F) --
SLICE_LIMIT = 10000
DSP_LIMIT  = 156
BRAM_LIMIT = 208

synth: $(SV_SOURCES)
	mkdir -p $(SYNTH_DIR)
	@echo "read_verilog -sv $(SV_SOURCES)" > $(SYNTH_DIR)/_synth_gen.ys
	@echo "hierarchy -check -top $(TOP_MODULE)" >> $(SYNTH_DIR)/_synth_gen.ys
	@echo "proc; flatten; opt" >> $(SYNTH_DIR)/_synth_gen.ys
	@echo "synth_ecp5 -top $(TOP_MODULE) -json $(SYNTH_DIR)/synth.json" >> $(SYNTH_DIR)/_synth_gen.ys
	@echo "tee -o $(SYNTH_DIR)/utilization.json stat -json" >> $(SYNTH_DIR)/_synth_gen.ys
	$(YOSYS) -s $(SYNTH_DIR)/_synth_gen.ys -l $(SYNTH_DIR)/synth.log -q
	@rm -f $(SYNTH_DIR)/_synth_gen.ys
	@python3 -c "\
import json, sys; \
data = json.load(open('$(SYNTH_DIR)/utilization.json')); \
mods = data.get('modules', {}); \
top = mods.get('$(TOP_MODULE)', mods.get('\\\\$(TOP_MODULE)', data.get('design', {}))); \
cells = top.get('num_cells_by_type', {}); \
lut4s = cells.get('LUT4', 0); \
ffs = cells.get('TRELLIS_FF', 0); \
ccu = cells.get('CCU2C', 0); \
pfumx = cells.get('PFUMX', 0); \
l6mux = cells.get('L6MUX21', 0); \
dsps = cells.get('MULT18X18D', 0); \
brams = cells.get('DP16KD', 0); \
approx_slices = (lut4s + 1) // 2; \
print('LUT4s:                  %d / %d' % (lut4s, $(SLICE_LIMIT) * 2)); \
print('Approx slices:          %d / $(SLICE_LIMIT)' % approx_slices); \
print('FFs (TRELLIS_FF):       %d' % ffs); \
print('Carry cells (CCU2C):    %d' % ccu); \
print('Muxes (PFUMX/L6MUX21):  %d / %d' % (pfumx, l6mux)); \
print('DSPs (MULT18X18D):      %d / $(DSP_LIMIT)' % dsps); \
print('BRAMs (DP16KD):         %d / $(BRAM_LIMIT)' % brams); \
ok = approx_slices <= $(SLICE_LIMIT) and dsps <= $(DSP_LIMIT) and brams <= $(BRAM_LIMIT); \
print('SYNTH: %s' % ('PASS' if ok else 'FAIL')); \
sys.exit(0 if ok else 1)"

# -- Verify hardware matches software --
verify:
	cmp -s $(SW_OUT_DIR)/sw_output.txt $(HW_OUT_DIR)/hw_output.txt
	@echo "VERIFY: PASS"

# -- Full score --
score: sw hw verify
	@echo ""
	@echo "--- Scoring ---"
	@python3 -c "\
import re; \
sw_txt=open('$(SW_OUT_DIR)/sw_metrics.txt').read(); \
hw_txt=open('$(HW_OUT_DIR)/hw_metrics.txt').read(); \
sw=float(re.search(r'SW_OPS_PER_SEC=([0-9.]+)', sw_txt).group(1)); \
hw=float(re.search(r'HW_OPS_PER_SEC=([0-9.]+)', hw_txt).group(1)); \
print('SW_OPS_PER_SEC=%.2f' % sw); \
print('HW_OPS_PER_SEC=%.2f' % hw); \
print('SPEEDUP=%.4fx' % (hw/sw));"

clean:
	rm -rf $(SIM_DIR)/ \
	       $(SYNTH_DIR)/synth.json \
	       $(SYNTH_DIR)/synth.log \
	       $(SYNTH_DIR)/utilization.json \
	       $(SYNTH_DIR)/_synth_gen.ys \
	       $(SW_OUT_DIR)/fir_sw \
	       $(SW_OUT_DIR)/sw_output.txt \
	       $(SW_OUT_DIR)/sw_metrics.txt \
	       $(HW_OUT_DIR)/hw_output.txt \
	       $(HW_OUT_DIR)/hw_metrics.txt

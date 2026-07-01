# Build a Machine

## The problem

Pick a computation. Any computation. Build an FPGA accelerator that does it
faster than software.

You write both sides: a software baseline (C, C++, Rust, or any language that
compiles in the provided Docker container) and a hardware accelerator in
synthesizable SystemVerilog. Your score is the speedup.

```
speedup = hardware_throughput / software_throughput
```

Make your software baseline as fast as you can. SIMD, multithreading, compiler
intrinsics -- whatever you want. The faster your software, the more impressive
your hardware speedup.

## Pick your battles

Your FPGA runs at 200-250 MHz with limited resources. A modern CPU runs at
4+ GHz with SIMD, out-of-order execution, and deep caches. Not every
computation is a good fit for FPGA acceleration. Choosing the right problem
is part of the challenge.

## Constraints

Hardware:
- Must synthesize on **Yosys targeting Lattice ECP5** within **10,000 slices** (~20,000 LUT4s)
- Full access to **156 DSP blocks** (18x18 multiply) and **208 block RAMs** (18Kbit each)
- Assumed clock: 200 MHz, single clock domain. This is a throughput multiplier for scoring, not a verified timing constraint. There is no place-and-route or timing analysis in the flow.
- No vendor IP blocks
- All RTL must be synthesizable

Software:
- Any language that compiles and runs in the provided Docker container (C, C++, Rust, etc.)
- Runs on x86-64
- No restrictions. SIMD, multithreading, intrinsics, hand-tuned assembly -- whatever you want.

## Interface

Edit `accelerator.sv`. The template has a streaming interface (AXI-Stream,
64-bit data, tlast for framing). You can change the data widths, add ports,
split into multiple modules, or restructure entirely. The template is a
starting point, not a requirement.

| Signal | Dir | Width | Description |
|--------|-----|-------|-------------|
| `clk` | in | 1 | 200 MHz clock |
| `rst_n` | in | 1 | Active-low synchronous reset |
| `s_axis_tdata` | in | 64 | Input data |
| `s_axis_tvalid` | in | 1 | Input valid |
| `s_axis_tready` | out | 1 | Input backpressure |
| `s_axis_tlast` | in | 1 | End of work unit |
| `m_axis_tdata` | out | 64 | Output data |
| `m_axis_tvalid` | out | 1 | Output valid |
| `m_axis_tready` | in | 1 | Output ready |
| `m_axis_tlast` | out | 1 | End of work unit |

AXI-Stream handshake: a transfer occurs when both `tvalid` and `tready` are
high on the rising clock edge.

You can add more `.sv` files. The `make synth` target picks up all `*.sv`
files in this directory, excluding `*_tb.sv` and `*_test.sv`. Use the same
convention in your Verilator build command so testbenches don't get
synthesized or double-compiled.

## Getting started

```bash
docker compose build
docker compose run test make sw       # run your software baseline
docker compose run test make hw       # run your hardware accelerator
docker compose run test make synth    # check area utilization
docker compose run test make verify   # check hardware matches software
docker compose run test make score    # measure speedup
```

Or, if you have Verilator and Yosys installed locally:

```bash
make sw
make hw
make synth
make verify
make score
```

## What to submit

1. **Hardware design** -- your accelerator in SystemVerilog (must pass `make synth`)
2. **Software baseline** -- your implementation in any compiled language (as optimized as you can)
3. **Test data / workload** -- input data shared between both implementations
4. **Testbench** -- drives the hardware, measures throughput, and proves correctness (`make verify` must pass)
5. **Architecture decision note** (max 2 pages) -- why this problem, how the hardware works, tradeoffs
6. **AI transcripts** -- full chat logs from any AI tools used (e.g. Codex, Claude Code, Cursor). We want to understand how you use AI tools to work through the problem.
7. **"What I didn't do and why"** (max 1 page)

## Makefile targets

| Target | Output |
|--------|--------|
| `make sw` | Build and run software baseline. Print `SW_OPS_PER_SEC=<float>`. |
| `make hw` | Verilate, build, and run hardware. Print `HW_OPS_PER_SEC=<float>`. |
| `make synth` | Yosys synthesis for ECP5. Print slice/DSP/BRAM counts. Fail if over budget. |
| `make verify` | Run both on the same input, compare outputs. Print PASS or FAIL. |
| `make score` | Run sw + hw + verify. Print speedup. |
| `make clean` | Remove build artifacts. |

Modify the Makefile to fit your project. These targets are the interface
we use for grading.

## How we evaluate

Speedup is one input, not the whole picture. We care about:

1. **Problem selection** -- did you pick a problem that plays to FPGA strengths? A modest speedup on a hard problem is more impressive than a huge speedup on a trivial one.
2. **Prioritization** -- did you spend effort on the things that matter most?
3. **Tradeoff judgment** -- do your resource allocation decisions make sense? Is LUT/DSP/BRAM usage intentional?
4. **Technical coherence** -- does everything hold together? Software, hardware, tests, and architecture note should all tell the same story.
5. **Honesty about uncertainty** -- did you clearly state what you don't know and where the comparison has limits?

A candidate with 3x speedup, a well-chosen problem, and a clear architecture note will score higher than a candidate with 100x speedup on a trivial computation.

Your speedup number depends on your host CPU. Report your CPU model in
the architecture note so we can contextualize the comparison.

## Timeline

1 week from receipt. No expected hour count.

## Tools

Use whatever tools, references, or AI assistants you want. The architecture
note should be your own reasoning in your own words.

# Wasabi: Floof Microarchitecture

Wasabi is designed to provide a combination of high-performance parallel integer computation and low-complexity, semi-stylized, accelerated 3D rendering.
To deliver acceptable rendering performance, especially in the face of limited memory bandwidth, the shader core in Wasabi, known as the multiprocessor or FMP, must be optimized.

The Wasabi shader core, known as the FMP, is what is sometimes referred to as a SIMT (Single-Instruction, Multiple-Thread) multiprocessor. The same program instruction is executed at the same time for multiple hardware-defined lanes, known as Slices, each with independent register files (the "Slice" `Sx` sets) and with access to a shared register file - the "Global" `Gx` set.

## Pipeline Concept

With a SIMT engine, the intention is to reduce instruction decoding and execution complexity by sharing the CPU frontend. Each slice thus contains the following:
- A set of execution units under several execution ports
- A register file
- An interface to the frontend
- An interface to the global register file
- An interface to memory and texture busses

## Out-of-Order (OoO) Operation

The FE is responsible for out-of-order issue. Several simplifications are made to achieve this in low area:
- All consensus branch (`BAE` and `BNE` or signaling (`SIG`) instructions are barriers.
- Virtual register management is handled by the FE and renaming information is shared.
	- The FE stores the truth virtual-architectural register mapping.
		- Assembled after shared commit FIFO fills, a barrier is asserted, or an exception triggers in any SL.
	- To accommodate `ExecMask` behavior, disabled SL's will simply perform source-to-destination copies on each virtual register operation.

### Decoding and Virtual Register Assignment

In the decode stage, an instruction is turned from its standard ISA bitfield into a wide horizontal microinstruction (Also uop). This uop contains mappings to specific SL execution ports, execution units, and virtual registers.

Virtual registers are mapped in a two stages. The ground-truth mapping contains architectural register values as last committed while an in-flight mapping contains virtual register information in an unrollable stack for instructions that are currently in-flight or committed but not retired. The Free Pool structure contains a mapping of all free virtual registers available for allocation. Note that there are two sets of these allocation structures: one for the `S`-sets and one for the `G`-set.




## The Frontend (`FE`)

The frontend provides a limited out-of-order execution capability. The primary intention of this is to reduce the latency of execution with regards to vector memory operations, which are extremely expensive. The following goals are kept in mind:
- 1 decode per cycle, with shallow decoding pipeline
- Predictive branch prefetch, fetching a cache line at once time.
- Support for managing at least 4 or 6 instructions at once.
- 1 instruction issued per cycle
	- Supporting the 4 execution ports of the SL's
	- Supporting the shared system control execution port

## The Shader Slice (`SL`)

An individual Slice contains a register file and the pipelines necessary to perform computation on that file and the global file.

The Global ID `GEID` input tells a slice its ID based on execution mask. This is used for certain MOV instructions.
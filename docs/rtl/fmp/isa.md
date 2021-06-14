# Floof MultiProcessor Programming Model & ISA

All graphics processing on Floof is directed by the Floof MultiProcessor, a wide programmable core.

The FMP works on independent Slices (sometimes known as lanes). 

Each FMP Slice performs scalar operations, with 64 32-bit wide registers `s0` to `s63`. Additionally, a global register set `g0` to `g63` provides another 64 registers shared between all Floof Slices. 

All Slices operate on the same instruction at the same time. Slices can be enabled and disabled programmatically.

FMP's architecture provides 32-bit integer and fixed-point mathematics, with an emphasis on fast fused multiply-accumulate, the core of 3D matrix mathematics.
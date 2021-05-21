# Floof Texture Subsystem (TEX)



## Floof TeXture InterFace
The Floof TeXture InterFace (TXIF) is the interface between texture units and the Floof Multiprocessor.

This unit manages a queue of Texture Sampling Requests (TSRs).
Each TSR contains an address to the texture's metadata and the position at which to sample.
To keep texture accesses fast, the TXIF maintains a 128-entry (CONFIRM?) texture metadata cache.

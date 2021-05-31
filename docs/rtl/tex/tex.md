# Floof TEXture Sampling Unit (TEX)



## Nearest Neighbor Pipeline
The texture unit is pipelined, allowing it to output up to one channel per cycle. This pipeline is optimized to combat the bottleneck created by the limited bandwidth of the FMPA bus. It is split into 3 major stages:
1. Parameters Input
2. Sample Retrieval
3. Sample Sending

These stages are pipelined, meaning that they can all service a different sample request at the same time. This allows the unit to output up to one color channel per cycle.

### Stage 1: Parameters Retrieval
1. Recieve Texture Metadata
2. Receive Sample X
3. Receive Sample Y
    - Stall if next stage stalled

This unit will stall if data is not available on the FMPA (`!dev_inbox`).

Switching texture metadata address between X and Y samples is undefined behavior.

### Stage 2: Sample Retrieval


| Cycle | Operations        |                   |                |                   |
| ----- | ----------------- | ----------------- | -------------- | ----------------- |
| 0     | Recv(TexMetaAddr) | Read(TextureMeta) |                |                   |
| 1     | Recv(SampleX)     | CoordDenorm(X)    |                |                   |
| 2     | Recv(SampleY)     | CoordDenorm(Y)    | CalcSampleAddr | Read(TextureData) |
| 3     | Send(R)           | ColorNorm(R)      |                |                   |
| 4     | Send(G)           | ColorNorm(G)      |                |                   |
| 5     | Send(B)           | ColorNorm(B)      |                |                   |
| 6     | Send(A)           | ColorNorm(A)      |                |                   |


Cycles 5 to 7 may be omitted in single-channel sampling.
Cycle 7 may be omitted in requests that omit Alpha.

## Optimizing for Throughput
With Floof Gen 1, the Texture Unit is not pipelined. Because of this, it takes 7 cycles to retrieve the color data per pixel. In future generations, the Texture Unit will be pipelined to allow for greater throughput.

The primary bottleneck for texture sampling is memory latency and bandwidth. A memory access will always take at least 1 cycle but it will likely take more to service the access. Additionally, with Floof's 32-bit memory bus, the access of 8-byte ETC/EAC blocks is more costly.

To improve texture bandwidth, two optional L1 caches are available:

The first is the Texture Metadata cache. 
The second is the Texture Data cache.

## Texture Metadata Format
![Texture Metadata Bitfield](tex_meta.svg)

Texture Metadata is sent as two 32-bit words. The first word indicates the texture format, the height exponent, and the width exponent, each as 4-bit unsigned integers. The rest of this word is reserved.

Width and height are stored as exponents to the base of 2 i.e `width = 2^widthExponent` or `width = 1 << widthExponent`. The texture format can be one of the following: 

| Texture Format ID | Name                   | Notes                   |
| ----------------- | ---------------------- | ----------------------- |
| `0b000 00`        | `RGB_24`               | 8, 8, 8                 |
| `0b001 00`        | `RGBA_32`              | 8, 8, 8, 8              |
| `0b000 01`        | `RGB_16`               | 5, 6, 5                 |
| `0b001 01`        | `RGBA_16`              | 4, 4, 4, 4              |
| `0b010 01`        | `RGB_15`               | 5, 5, 5 with MSB unused |
| `0b011 01`        | `RGBA_15_PUNCHTHROUGH` | 5, 5, 5, 1              |
| `0b000 10`        | `RGB_ETC2`             |                         |
| `0b001 10`        | `RGBA_ETC2`            |                         |
| `0b010 10`        | RESERVED               |                         |
| `0b100 10`        | RESERVED               |                         |
| `0b101 10`        | `R_EAC_SIGNED`         |                         |
| `0b000 11`        | `RGB_24_TILED`         | 16x16 tiles             |
| `0b001 11`        | `RGBA_32_TILED`        | 16x16 tiles             |
| `0b010 11`        | `RGB_16_TILED`         | 16x16 tiles             |
| `0b011 11`        | `RGBA_16_TILED`        | 16x16 tiles             |
| `0b100 11`        | `R_8_TILED`            | 16x16 tiles             |
| `0b101 11`        | `R_16_TILED`           | 16x16 tiles             |

All other Format IDs are reserved.

Note: Tiled textures must be sized minimum 16x16.

The second word is the base address of the texture. These two words are sent in order on the FMPA bus.

## Texture Unit Command Tag Format
The Texture Unit receives commands in the tag field of data sent on the FMPA bus from the FMP.
It uses the destination ID `0b001`.

Opcodes are specified in three bits:

| Op-code | Name         | Description                                             |
| ------- | ------------ | ------------------------------------------------------- |
| `0b000` | SetTexture   | Set Texture Metadata Address for texture to sample from |
| `0b001` | StreamCoords | Streaming of sampling coordinates in order X and then Y |


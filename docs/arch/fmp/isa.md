# Wasabi: Floof Multiprocessor Instruction Set Architecture

All graphics processing on Floof is directed by the Floof Multiprocessor, a wide programmable SIMT core.

The FMP works on independent slices (commonly known as lanes). 

Each FMP Slice performs scalar operations, with 64 32-bit wide registers `s0` to `s63`. Additionally, a global register set `g0` to `g63` provides another 64 registers shared between all FMP slices. Global set registers must be loaded into local registers before use. The lowest number slice is given priority when writing to the Global set. Global-Global operations will not execute when no slices are enabled except with specific branching instructions (All branches are global).

All slices execute the same instruction at the same time. Slices can be enabled and disabled programmatically. The FMP's architecture provides 32-bit integer and fixed-point mathematics, with an emphasis on fast fused multiply-accumulate, the core of 3D matrix mathematics.

The FMP features no native multitasking. A Floof task is started by the host processor and the host can either suspend/resume it, stop it, or wait for it to signal completion. There is no hardware multitasking mechanism.


## Instruction Set
The FMP utilizes 4-byte wide instructions. These are executed on all enabled slices sequentially, maintaining shared *Instruction Pointer* `ip` register that can otherwise be modified with a subset of control flow instructions.

### Encoding

To simplify decoding, a 9-bit opcode (split into a 4-bit group code and a 5-bit instruction code) is used to refer to all instructions. The other 23 bits can be utilized as parameters for the instruction and will be encoded differently per instruction.

![Generic FMP instruction encoding](enc_generic.svg)

*Generic FMP instruction encoding*

Several shared encoding formats are then specified for common instruction inputs:

### Encoding A/A0/A1/A2/A3
Encoding A is the most common encoding format. It allows the specification of up to 3 registers: `Rx`, `Ry`, and `Rz` - ideal for most operations.

Unless specified, `Rx`, `Ry`, and `Rz` are provided in that order for operations using 1, 2, or 3 registers, respectively. No registers can also be specified.

The rest of the *Parameters* space (at least the 5 MSBs) is always reserved for parameters. Any unused register space may be used for parameters.

![FMP Encoding A](enc_a.svg)

*FMP Encoding A*

### Encoding B
Encoding B supports the storage of large immediates into a single register. 

See [**`MOVI`**](#movg---move-register-tofrom-global-indexed-by-absolute-slice-id) for formatting information.

![FMP Encoding B](enc_b.svg)

*FMP Encoding B*

### Instruction Groups

| Group Code | Group Name                           |
| ---------- | ------------------------------------ |
| `0b0000`   | Registers, Memory, & Texture Access  |
| `0b0001`   | Control Flow & Conditional Execution |
| `0b0010`   | Logic Operations                     |
| `0b0011`   | Mathematics                          |
| `0b0100`   | Raster and Tile Control              |

---

## Group `0b0000` - Registers, Memory, & Texture Access

### `MOV` - Move Register to Register
Move data from a register `Rs` to a register `Rd`.

```
MOV Sd, Ss
MOV Gd, Gs
MOV Sd, Gs
MOV Gd, Ss
```

When moving to `Gd` from `Ss`, the value used will be from the lowest numbered enabled Slice (i.e. Slice 0 if it is enabled). 

| Instruction  | Encoding | Opcode     | Notes |
| ------------ | -------- | ---------- | ----- |
| `MOV Sd, Rs` | A2       | `5'b00001` |       |

### `MOVG{A/E}{SL/SR}` - Move Register to/from Global.
Move data between a scalar register and a global register with multiple indexing modes. 
A base register index is specified in `Gs`/`Gd` and is augmented with the following options:

- `A` Absolute mode will use the Slice's `sliceID`, from 0 to parameterized `fmp_WIDTH - 1` (up to 31).
- `E` Enabled mode will use the enabled-slice ID, where the lowest enabled slice (as sorted by `sliceID`) is 0
and each additional enabled slice is incremented by one.
- `SL`/`SR` Shuffle Left and Shuffle Right modes will shuffle the global source or destination by 1 in the respective direction,
with rotation-like overflow behavior for the first/last slice.


**Note**: Only enabled slices will perform this operation, the remaining registers will not be modified.

```
MOVG{A/E}{SL/SR} Sd, Gs
MOVG{A/E}{SL/SR} Sd, Gs
MOVG{A/E}{SL/SR} Sd, Gs 
MOVG{A/E}{SL/SR} Gd, Ss
```

| Instruction               | Encoding | Opcode     | Notes                               |
| ------------------------- | -------- | ---------- | ----------------------------------- |
| `MOVG{A/E}{SL/SR} Rd, Rs` | A2       | `5'b00010` | `Flags = {0, ..., 1'E, 1'SL, 1'SR}` |

### `MVI` - Move Immediate to Register
Move an immediate value to a specified register `Rd`.

```
MVI Sd, imm
MVI Gd, imm
```

This immediate is 12 bits and expands to a full 32-bit value using the formats specified by the following `Imm Type` table:

| Type ID | Mnemonic         | Type                             | Format                                              |
| ------- | ---------------- | -------------------------------- | --------------------------------------------------- |
| `0b000` | `uint`           | Unsigned Integer                 | Lower 12 bits of an unsigned integer, zero extended |
| `0b001` | `sint`           | Signed Integer                   | Lower 12 bits of a signed integer, sign extended    |
| `0b010` | `q6` or `q6.6`   | Mixed-format Fixed Point         | 6 integer bits, 6 fractional bits, sign extended    |
| `0b011` | `q12` or `q12.0` | Whole Number Fixed Point         | 12 integer bits, 0 fractional bits, sign extended   |
| `0b100` | `q2` or `q2.10`  | Fractional/Magnitude Fixed Point | 2 integer bits, 10 fractional bits, sign extended   |

Unassigned bits, unless changed by sign extension, default to zero. The format is automatically chosen by the Floof Assembler.

| Instruction   | Encoding | Opcode     | Notes                             |
| ------------- | -------- | ---------- | --------------------------------- |
| `MVI Rd, imm` | B        | `5'b00011` | See [**Encoding B**](#encoding-b) |

### `RELIP` - Move IP + Immediate to Register 
Add the instruction pointer to an immediate signed integer and puts it in `Rd`. 

```
RELIP Gd, imm
RELIP Sd, imm
``` 

| Instruction     | Encoding | Opcode     | Notes                            |
| --------------- | -------- | ---------- | -------------------------------- |
| `RELIP Rd, imm` | B        | `5'b00100` | Imm Type should be `uint`/`sint` |

### `MVS` - Move Special Register
Reserved (Opcode `5'b00101`).


### `LD` - Load Word
Fetch 32-bit word from memory using address in `Rs`, designating output in register `Rd`.

```
LD Sd, Ss
LD Sd, Gs
LD Gd, Gs
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `LD Rd, Rs` | A2       | `5'b00110` |       |

### `ST` - Store Word
Store a data word from register `Rs` at the address in `Rd`.
```
ST Sd, Ss
ST Gd, Gs
ST Sd, Gs
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `ST Rd, Rs` | A2       | `5'b01000` |       |

### `SAMPE`/`SAMPR`/`SAMPC` - Sample Texture Empty/Repeating/Clamped

Perform a texture sample.

All parameters are specified in [**register pairs**](#register-pairs).

`Rt` contains the Texture Metadata pair [**as specified**](#texture-specifier-format-for-rt).\
`Rp` contains the sampling coordinates *X* and *Y*, respectively. This is destroyed and replaced with *R* and *G*, respectively.\
`Rq` will be destroyed and replaced with *B* and *A* respectively. 

Colors are represented in fixed-point between 0.0 and 1.0.\
**Note** that texture channels not explicitly defined by the texture are set to 1.0 in-boundary.

Sample with per-slice texture metadata specification:
```
SAMPE Sp, Sq, St
SAMPR Sp, Sq, St
SAMPC Sp, Sq, St
```

Sample with global texture metadata specification:
```
SAMPE Sp, Sq, Gt
SAMPE Gp, Gq, Gt

SAMPR Sp, Sq, Gt
SAMPR Gp, Gq, Gt

SAMPC Sp, Sq, Gt
SAMPC Gp, Gq, Gt
```

#### Texture Sampling Modes
 - `SAMPE` Empty - Returns `RGBA(0.0, 0.0, 0.0, 0.0)` past edge.
 - `SAMPR` Repeating - Samples at module coordinate past edge.
 - `SAMPC` Clamped - Samples at nearest edge pixel past edge.

These modes do not affect sampling within the boundaries of the texture.


#### Texture Specifier Format for `Rt`
The first register in the register pair is the base address of the texture. The second is the contains width, height, and format as specified in the [TEX docs](../tex/tex.md).


| Instruction        | Encoding | Opcode     | Notes              |
| ------------------ | -------- | ---------- | ------------------ |
| `SAMPE Rp, Rq, Rt` | A3       | `5'b00111` | `Flags = 3'b000` |
| `SAMPR Rp, Rq, Rt` | A3       | `5'b00111` | `Flags = 3'b001` |
| `SAMPC Rp, Rq, Rt` | A3       | `5'b00111` | `Flags = 3'b010` |


---


## Group `0b0001` - Control Flow & Conditional Execution

### FMP Conditional Execution Model
Each slice stores a conditional pass flag `T`. This can be used to perform various actions after a condition test. The first such action is the ability to directly enable or disable a slice based on this value, via the `ENT` instruction. 

If more control is needed, the `MSKS` instruction allows for a mask to be generated in a global register based on the values of the `T` flags, where Slice 0's `T` flag is the LSB and so on. This enables, for example, the ability to save the results of a conditional test for later or to use bitwise operations to describe more complex conditions. The `ENM` instruction will accept such a mask.

Alternatively, the `SEL` instruction allows for selecting a value between two specified registers and storing that value in a third register based on the `T` flag.

The `MSKL` instruction can load a mask from the global register set into the `T` flags of each slice in the order specified above. The `BFG` instruction can also be used to generate a mask enabling a contiguous amount of slices.

Tests can be performed with the `TST` operation. This instruction takes a condition code.

### `ENBT` - Enable Slices by `T` flag
Enable a given slice by whether or not its `T` flag is set. 

This instruction will execute for all slices irrespective of `ExecMask`

```
ENBT
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `ENBT`      | A0       | `5'b00000` |       |

### `ENA` - Enable All Slices
Enable all slices unconditionally, irrespective of `ExecMask`.
```
ENBT
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `ENA`       | A0       | `5'b00001` |       |

### `LDMSK` - Load Mask from `T` flags
Generate a mask in the format described in [**FMP Conditional Execution Model**](#fmp-conditional-execution-model) and place it in the global register `Gd`.
```
STMSK Gd
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `STMSK Gd`  | A1       | `5'b00010` |       |
### `STMSK` - Store Mask into `T` flags
Load the mask in global register `Gs` into `T` flags. See [**FMP Conditional Execution Model**](#fmp-conditional-execution-model) for mask format information.
```
MSKL Gs
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `MSKL Gs`   | A1       | `5'b00011` |       |

### `STXM` - Store Current Execution Mask
Save the current execution mask to a global register `Gd`

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `STXM Gd`   | A1       | `5'b00100` |       |

### `LDT` - Load `T` flag as Logical Boolean into Register
```
LDT Sd
```

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `LDT Sd`    | A1       | `5'b00101` |       |

### `TST` - Test and Store Result in `T` flag
```
TST Cond
TST Cond, Ra
TST Cond, Ra, Rb
```

```
TST !Cond
TST !Cond, Ra
TST !Cond, Ra, Rb
```

### Test Condition Codes
| Code    | Name                        | Mnemonic | Operation                   | Num. of Operands |
| ------- | --------------------------- | -------- | --------------------------- | ---------------- |
| `0b000` | Zero                        | `ZRO`    | `Ra == 32'0`                | 1                |
| `0b001` | Equal                       | `EQU`    | `Ra == Rb`                  | 2                |
| `0b010` | Unsigned Less Than          | `ULT`    | `(u32)Ra < (u32)Rb`         | 2                |
| `0b011` | Unisgned Less-Than or Equal | `ULE`    | `(u32)Ra <= (u32)Rb`        |                  |
| `0b100` | Signed Less Than            | `SLT`    | `(s32)Ra < (s32)Rb`         | 2                |
| `0b101` | Signed Less-Than or Equal   | `SLE`    | `(s32)Ra <= (s32)Rb`        |                  |
| `0b110` | Negative                    | `NEG`    | `Ra[31] == 1'b1`            | 1                |
| `0b111` | Consensus                   | `CNS`    | `Ra & ExecMask == ExecMask` | 1                |

| Instruction        | Encoding | Opcode     | Notes                                |
| ------------------ | -------- | ---------- | ------------------------------------ |
| `TST COND, Ra`     | A1       | `5'b00110` | `Flags = {0 ..., 1'Invert, 3'Cond}`  |
| `TST COND, Ra, Rb` | A2       | `5'b00110` | `Flags = {0 ..., 1'Invert, 3'bCond}` |

### `SEL` - Select Value of Register
Set register `Sd` with `St` or `Sf`, depending on if the Slice's `T` flag is set or clear, respectively.

```
SEL Sd, St, Sf
```

| Instruction      | Encoding | Opcode     | Notes |
| ---------------- | -------- | ---------- | ----- |
| `SEL Sd, St, Sf` | A3       | `5'b00111` |       |

### `BR` - Branch

Unconditional branch to register address.

This branch will always be taken, irrespective of `ExecMask`. The `ExecMask` will not be changed.

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `BR Gd`     | A1       | `5'b01000` |       |

### `BAE` - Branch if Any Slices Enabled 

Branch if any slices are enabled, when `ExecMask != 0x00000000`

The `ExecMask` will not be changed.

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `BAE Gd`    | A1       | `5'b01001` |       |

### `BNE` - Branch if No Slices Enabled & Re-enable All

Branch if no slices are enabled (`ExecMask = 0x00000000`).
All slices will be enabled such that `ExecMask = 0xFFFFFFFF`.

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `BNE Gd`    | A1       | `5'b01010` |       |

### `SIG` - Signal Completion or Error
Signal completion or failure of a task. This instruction has the special Encoding C. 

Signals have a host: 
- the CPU
- the Raster Unit.

They also have a 5-bit signed code:
 - A positive code signifies success.
 - A negative code signifies failure.

Signals can be asynchronous or synchronous given the `ASYNC` bit:
- A `0` indicates Floof should wait for a continuation signal from the host
- A `1` indicates Floof should push the signal and continue execution

**Note:** Asynchronous signaling is not available with Raster.

Finally, a global status register `Gs` can be be passed.

| Instruction  | Encoding | Opcode     | Notes |
| ------------ | -------- | ---------- | ----- |
| `SIG Rd, Rs` | A2       | `5'b01001` |       |

### `BAR` - Instruction Barrier

The core will pause instruction issue until all current in-flight instructions, include memory/texture accesses, are completed.

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `BAR`       | A0       | `5'b01010` |       |

### `NOP` - Do Nothing

No operation will be performed.

| Instruction | Encoding | Opcode     | Notes |
| ----------- | -------- | ---------- | ----- |
| `BAR`       | A0       | `5'b01011` |       |
    
---

## Group `0b0010` - Logic Operations

### `AND` - Bitwise AND
```
AND Sd, Ra, Rb
AND Gd, Ga, Gb
```

| Instruction      | Encoding | Opcode     | Notes |
| ---------------- | -------- | ---------- | ----- |
| `AND Rd, Ra, Rb` | A3       | `5'b00000` |       |

### `OR` - Bitwise OR
```
OR Sd, Ra, Rb
OR Gd, Ga, Gb
```
| Instruction     | Encoding | Opcode     | Notes |
| --------------- | -------- | ---------- | ----- |
| `OR Rd, Ra, Rb` | A3       | `5'b00001` |       |

### `XOR` - Bitwise XOR
```
XOR Sd, Ra, Rb
XOR Gd, Ga, Gb
```

| Instruction      | Encoding | Opcode     | Notes |
| ---------------- | -------- | ---------- | ----- |
| `XOR Rd, Ra, Rb` | A3       | `5'b00010` |       |

### `NOT` - Bitwise NOT
```
NOT Sd, Ra
NOT Gd, Ga
```
| Instruction  | Encoding | Opcode      | Notes |
| ------------ | -------- | ----------- | ----- |
| `NOT Rd, Ra` | A2       | `5'b00011` |       |

### `LNOT` - Logical NOT
```
LNOT Sd, Ra
LNOT Gd, Ga
```

| Instruction   | Encoding | Opcode      | Notes |
| ------------- | -------- | ----------- | ----- |
| `LNOT Rd, Ra` | A2       | `5'b00100 ` |       |

### `PCNT` - Population Count
Find the amount of 1s in a given register `Rs` and store it in a register `Rd`.
```
PCNT Gd, Gs
PCNT Sd, Ss
```

| Instruction   | Encoding | Opcode      | Notes |
| ------------- | -------- | ----------- | ----- |
| `PCNT Rd, Ra` | A2       | `5'b00101 ` |       |

### `BITS` - Make Bitfield
Make bitfield with *n* enabled bits enabled starting at bit 0 where *n* is specified by register `Rn`.

This bitfield is stored at `Rd`.

```
BITS Sd, Rn
BITS Gd, Gn
```

| Instruction   | Encoding | Opcode     | Notes |
| ------------- | -------- | ---------- | ----- |
| `BITS Rd, Rn` | A2       | `5'b00110` |       |

### `BE` - Bit Extract
### `BS` - Bit Set
### `BC` - Bit Clear

### `LSR` - Logical Shift Right
### `LSL` - Logical Shift Left
### `ASR`- Arithmetic Shift Right

### `FFS` - Find First Set Bit
### `REV` - Bit Reverse
### `RTHL`/`RTHH` - Retrieve Half-word Low/High

### `RTB` - Retrieve Byte Of Word

---

## Group `0b0011` - Mathematics

All binary mathematical operations are as such:
```
BINOP Sd, Sa, Sb
BINOP Gd, Sa, Sb
BINOP Gd, Ga, Gb
```

### `ADD` - Add

```
ADD Sd, Sa, Sb
ADD Gd, Ga, Gb
```

### `SUB` - Subtract

### `UMULI`/`SMULI` - Unsigned/Signed Multiply Integer
### `MULQ` - Signed Multiply Fixed
### `UFMAI`/`SFMAI` - Unsigned/Signed Multiply-Accumulate Integer
### `MACQ` - Signed Multiply-Accumulate Fixed

### `UDIVI`/`SDIVI` - Unsigned/Signed Divide Integer
### `DIVQ` - Signed Divide Fixed-Point
### `UREM` - Unsigned/Signed Remainder Integer

### `SQRTQ` - Fixed Signed Square Root
### `RSQTQ` - Fixed Signed Reciprocal Square Root

### `ABS` - Absolute Value
### `NEG` - Negate Number
### `SXT` - Sign Extend

### `UFLOOR`/`SFLOOR` - Unsigned/Signed Round Number Down
### `UCEIL`/`SCEIL` - Unsigned/Signed Round Number Up
### `ROUND` - Round Number to Closest Integer

### `SIN` - Trigonometric Sine

### `COS` - Trigonometric Cosine

---

## Group `0b0100` Raster and Tile Control

### `TILD` - Tile Load

### `TIST` - Tile Store

### `PXL` -  Pixel Load

### `PXS` - Pixel Store


---

## Appendix

### Register Pairs
A register pair consists of two registers and is specified by an even numbered register, where the even register $R_n$ specifies the first/lower 4 bytes while the odd register $R_{n + 1}$ specifies the second/higher 4 bytes.
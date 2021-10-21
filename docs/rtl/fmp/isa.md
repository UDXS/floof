# FloofMP32.1: The First-Generation Floof MultiProcessor Instruction Set Architecture

All graphics processing on Floof is directed by the Floof MultiProcessor, a wide programmable multiprocessor core.

The FMP works on independent Slices (sometimes known as lanes). 

Each FMP Slice performs scalar operations, with 64 32-bit wide registers `S0` to `S63`. Additionally, a global register set `G0` to `G63` provides another 64 registers shared between all FMP Slices. Global set registers must be loaded into local registers before use. The lowest number slice is given priority when writing to the Global set.

All Slices execute the same instruction at the same time. Slices can be enabled and disabled programmatically.

The FMP's architecture provides 32-bit integer and fixed-point mathematics, with an emphasis on fast fused multiply-accumulate, the core of 3D matrix mathematics.

The FMP features no native multitasking. A Floof task is started by the host processor and the host can either suspend/resume it, stop it, or wait for it to signal completion. There is no hardware multitasking mechanism.


## Instruction Set
The FMP utilizes 4-byte wide instructions. These are executed on all enabled slices sequentially, maintaining shared *Instruction Pointer* `ip` register that can otherwise be modified with a subset of control flow instructions.

### Encoding

To simplify decoding, a 9-bit opcode (split into a 4-bit group code and a 5-bit instruction code) is used to refer to all instructions. The other 23 bits can be utilized as parameters for the instruction and will be encoded differently per instruction.

![Generic FMP instruction encoding](enc_generic.svg)

*Generic FMP instruction encoding*

Several shared encoding formats are then specified for common instruction inputs:

### Encoding A
Encoding A is the most common encoding format. It allows the specification of up to 3 registers: `Rd`, `Ra`, and `Rb`.

The rest of the *Parameters* space (at least 5 MSBs) is reserved for flags. The specification of whether a register is within the Global or Slice set is done with the top 0 to 3 bits, depending on what the instruction requires and allows.

![FMP Encoding A](enc_a.svg)

*FMP Encoding A*


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

### `MVG` - Move Register to/from Global, Aligned by Absolute Slice ID


### `MVGE` - Move Register to/from Global, Aligned by Enabled Slice ID

### `MVI` - Move Immediate to Register
Move an immediate value to a specified register `Rd`.
```
MVI Sd, imm
MVI Gd, imm
```

This immediate is 12 bits and expands to a full 32-bit value using the formats specified by the following `ImmediateFormat` table:

| Type ID | Type                             | Format                                              |
| ------- | -------------------------------- | --------------------------------------------------- |
| `0b000` | Unsigned Integer                 | Lower 12 bits of an unsigned integer, zero extended |
| `0b001` | Signed Integer                   | Lower 12 bits of a signed integer, sign extended    |
| `0b010` | Mixed-format Fixed Point         | 6 integer bits, 6 fractional bits, sign extended    |
| `0b011` | Whole Number Fixed Point         | 12 integer bits, 0 fractional bits, sign extended   |
| `0b100` | Fractional/Magnitude Fixed Point | 2 integer bits, 10 fractional bits, sign extended   |

Unassigned bits, unless changed by sign extension, default to zero. The format is automatically chosen by the Floof Assembler.

### `RELPC` - Move PC + Immediate to Register 


### `MVS` - Move Special Register


### `LD` - Queue Word Load
Queue memory word fetch with address in `Rs`, designating output in register `Rd`. `Rd` is only guaranteed to be written after `COMMIT`.
```
LD Sd, Ss
```
Queue a fetch of data at the address in `Ss` in the SMAU (per-Slice **Memory Access Unit**), , using the per-slice `Sx` register set.

```
LD Gd, Gs
```
Queue a fetch in the GMAU (**Global** MAU), using the global `Gx` register set.

### `SAMPR` & `SAMPC` - Sample Texture Repeating/Clamped
Queue texture sampling request on the TMAU (**Texture** MAU).

Texture Metadata is specified in a [**register pair**](#register-pairs).

```
SAMPR St, Sx, Sy
SAMPC St, Sx, Sy
```

Sample with per-Slice texture metadata specification.

```
SAMPR Gt, Sx, Sy
SAMPC Gt, Sx, Sy
```
Sample with Globally-specified texture metadata.

### `ST` - Store Word
Queue store of data in register `Rs` at the address `Rd`.
```
ST Sd, Ss
```

```
ST Gd, Gs
```

```
ST Sd, Gs
```
This enables copying uniforms into "per-job" main-memory storage.

### `COMMIT` - Complete Fetches/Stores and Flush Data to Registers
The GMAU and active SMAUs will complete any queued memory fetch/store requests (done via `FETCH`) and flush the loaded data to the destination registers specified in the `FETCH` instruction. If no fetch requests are queued, this instruction will do nothing.

```
COMMIT
```

### `DISCARD` - Halt Pending Memory Fetches/Stores and Discard All Loaded Data.
All GMAU and active SMAUs will stop any pending memory bus transactions, clear the fetch/store queue, clear loaded data, and not write to any registers.

```
DISCARD
```

---

## Group `0b0001` - Control Flow & Conditional Execution

### FMP Conditional Execution Model
On the FMP, each slice stores a conditional pass flag `T`. This can be used to perform various actions after a test. The first such action is the ability to directly enable or disable a slice based on this value, via the `ENT` instruction. 

If more control is needed, the `MSKS` instruction allows for a mask to be generated in a global register based on the values of the `T` flags, where Slice 0's `T` flag is the LSB and so on. This enables, for example, the ability to save the results of a conditional test for later or to use bitwise operations to describe more complex conditions. The `ENM` instruction will accept such a mask.

Alternatively, the `SEL` instruction allows for selecting a value between two specified registers and storing that value in a third register based on the `T` flag.

The `MSKL` instruction can load a mask from the global register set into the `T` flags of each slice in the order specified above. The `BFG` instruction can also be used to generate a mask enabling a contiguous amount of slices.

Tests can be performed with the `TST` operation. This instruction takes a condition code.

### `ENT` - Enable Slices by `T` flag
Enable a given slice by whether or not its `T` flag is set.
```
ENT
```

### `ENM` - Enable Slices by Global Mask
Enable slices by using a mask specified by a global register `Gs`. See [**FMP Conditional Execution Model**](#fmp-conditional-execution-model) for mask format information.
```
Enm Gs
```

### `TMST` - Store Mask from `T` flags
Generate a mask in the format described in [**FMP Conditional Execution Model**](#fmp-conditional-execution-model) and place it in the global register `Gd`.
```
MSKS Gd
```

### `EMST` - Store Current Execution Mask
Save the current execution mask to a global register `Gd`

### `MSKL` - Load Mask into `T` flags
Load the mask in global register `Gs` into `T` flags. See [**FMP Conditional Execution Model**](#fmp-conditional-execution-model) for mask format information.
```
MSKL Gs
```

### `LDT` - Load `T` flag as Logical Boolean into Register
```
LDT Sd
```

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
| Code    | Name                 | Mnemonic | Operation                   | Num. of Operands |
| ------- | -------------------- | -------- | --------------------------- | ---------------- |
| `0b000` | Zero                 | `ZRO`    | `Ra == 32'0`                | 1                |
| `0b001` | Equal                | `EQU`    | `Ra == Rb`                  | 2                |
| `0b010` | Unsigned Less Than   | `ULT`    | `(u32)Ra < (u32)Rb`         | 2                |
| `0b011` | Unsgned Greater Than | `UGT`    | `(u32)Ra > (u32)Rb`         | 2                |
| `0b100` | Signed Less Than     | `SLT`    | `(s32)Ra < (s32)Rb`         | 2                |
| `0b101` | Signed Greater Than  | `SGT`    | `(s32)Ra > (s32)Rb`         | 2                |
| `0b110` | Negative             | `NEG`    | `Ra[31] == 1'b1`            | 1                |
| `0b111` | Consensus            | `CNS`    | `Ra & ExecMask == ExecMask` | 1                |

### `SEL` - Select Value of Register
Set register `Sd` with `St` or `Sf`, depending on if the Slice's `T` flag is set or clear, respectively.
```
SEL Sd, St, Sf
```

### `BR` - Branch


### `BEN` - Branch if Any Slices Enabled 


### `BNEN` - Branch if No Slices Enabled

### `SIG` - Set Signal for Host Processor

### `NOP` - Do Nothing


---

## Group `0b0010` - Logic Operations

### `AND` - Bitwise AND
```
AND Sd, Sa, Sb
AND Gd, Ga, Gb
```

### `OR` - Bitwise OR
```
OR Sd, Sa, Sb
OR Gd, Ga, Gb
```

### `XOR` - Bitwise XOR
```
XOR Sd, Ga, Sb
XOR Gd, Ga, Gb
```

### `NOT` - Bitwise NOT
```
NOT Sd, Ga, Sb
NOT Gd, Ga, Gb
```

### `LNOT` - Logical NOT
```
LNOT Sd, Ga, Sb
LNOT Gd, Ga, Gb
```

### `LBOOL` - Logical Boolean Format
Put register `Rs` in `Rd` in Boolean Format. Allows for bitwise operations (except `NOT`) to act as logical operations safely.

If `Rs` is zero, `Rd` will equal `0`.

If `Rs` is non-zero, `Rd` will equal `1`. 
```
LBOOL Sd, Ss
LBOOL Gd, Gs
```

### `PCNT` - Population Count
Find the amount of 1s in a given register `Rs` and store it in a register `Rd`.
```
PCNT Gd, Gs
PCNT Sd, Ss
```

### `BITS` - Make Bitfield
Make bitfield with *n* bits enabled starting at bit 0 where *n* is specified by register `Rn`.

This bitfield is stored at `Rd`

```
BITS Sd, Sn
BITS Gd, Gn
```

### `BE` - Bit Extract
### `BS` - Bit Set
### `BC` - Bit Clear

### `LSR` - Logical Shift Right
### `LSL` - Logical Shift Left
### `ASR`- Arithmetic Shift Right

### `REV` - Bit Reverse
### `REVH`/`REVL` - Bit Reverse High/Low 16 bits
### `FFS` - Find First Set Bit

### `RTHL`/`RTHH` - Retrieve Half-word Low/High

---

## Group `0b0011` - Mathematics

### `ADD` - Add

```
ADD Sd, Sa, Sb
ADD Gd, Ga, Gb
```

### `SUB` - Subtract

```
SUB Sd, Sa, Sb
SUB Gd, Ga, Gb
```

### `UMULI`/`SMULI` - Unsigned/Signed Multiply Integer
### `MULQ` - Signed Multiply Fixed
### `UFMAI`/`SFMAI` - Unsigned/Signed Multiply-Accumulate Integer
### `MACQ` - Signed Multiply-Accumulate Fixed

### `UDIVI`/`SDIVI` - Unsigned/Signed Divide Integer
### `DIVQ` - Signed Divide Fixed-Point
### `UREM` - Unsigned/Signed Remainder Integer
### `RCPQ` - Signed Reciprocal of Fixed

### `SQRTQ` - Fixed Signed Square-Root

### `ABS` - Absolute Value
### `NEG` - Negate Number
### `SXT` - Sign Extend

### `UFLOOR`/`SFLOOR` - Unsigned/Signed Round Number Down
### `UCEIL`/`SCEIL` - Unsigned/Signed Round Number Up
### `ROUND` - Round Number to Closest


## Group `0b0100` Raster and Tile Control

### `TILD` - Tile Load

### `TIST` - Tile Store

### `PLD` - Pixel Load

### `PST` - Pixel Store

### `TOFS` - Set Tile Coordinate Offset

### `TOFL` - Load Tile Coordinate Offset 

### `TRIL` - Triangle Load


### `BARYP` - Barycentric Coordinate At Pixel


## Register Pairs
A register pair consists of two registers and is specified by an even numbered register, where the even register (*n*) specifies the lower 4 bytes while the odd register (*n* + 1) specifies the higher 4 bytes.
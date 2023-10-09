# Floof TEXture Sampling Unit (TEX)


## Texture Metadata Format
![Texture Metadata Bitfield](tex_meta.svg)

Texture Metadata is sent as two 32-bit words. The first word indicates the texture format, the height exponent, and the width exponent, each as 4-bit unsigned integers. The rest of this word is reserved.

Width and height are stored as exponents to the base of 2 i.e `width = 2^widthExponent` or `width = 1 << widthExponent`. The texture format can be one of the following: 

| Texture Format ID | Name                     | Notes                   |
| ----------------- | ------------------------ | ----------------------- |
| `0b000 00`        | `RGB_24`                 | 8, 8, 8                 |
| `0b001 00`        | `ARGB_32`                | 8, 8, 8, 8              |
| `0b000 01`        | `RGB_16`                 | 5, 6, 5                 |
| `0b001 01`        | `ARGB_16`                | 4, 4, 4, 4              |
| `0b010 01`        | `RGB_15`                 | 5, 5, 5 with MSB unused |
| `0b011 01`        | `ARGB_15_PUNCHTHROUGH`   | 5, 5, 5, 1              |
| `0b000 10`        | `RGB_ETC2`               |                         |
| `0b001 10`        | `ARGB_ETC2`              |                         |
| `0b010 10`        | `ARGB_ETC2_PUNCHTHROUGH` |                         |
| `0b100 10`        | `R_EAC_UNSIGNED`         |                         |
| `0b101 10`        | `R_EAC_SIGNED`           |                         |
| `0b000 11`        | `RGB_24_TILED`           | 16x16 tiles             |
| `0b001 11`        | `ARGB_32_TILED`          | 16x16 tiles             |
| `0b010 11`        | `RGB_16_TILED`           | 16x16 tiles             |
| `0b011 11`        | `ARGB_16_TILED`          | 16x16 tiles             |
| `0b100 11`        | `R_8_TILED`              | 16x16 tiles             |
| `0b101 11`        | `R_16_TILED`             | 16x16 tiles             |

All other Format IDs are reserved.

Note: Tiled textures must be sized minimum 16x16.
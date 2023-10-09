# Anf Floof MEMory bus
Floof utilizes two, 32-bit busses to allow internal devices to access main memory. In both busses, there is a single bus master, the EMAI (External Memory Access Interface). One of these busses is the read bus and the other is the write bus.

The primary goal of this bus architecture is to support transfers of up to 1 word/cycle.

## Reading Data
Requests are done in 32-bit words with no alignment requirements.

To make a memory read request, a device puts an address on the `rd_addr` line and then raises `rd_ready`. When the EMAI has serviced the request, it will put the requested word on the `rd_data` line and will then pulse the device's `rd_valid` line high for a cycle. 

Additionally, the EMAI raises the device's `rd_sel` line to indicate that it is communicating with the device specifically. If `rd_sel` is not raised, the device must ignore `rd_addr` and `rd_valid`.

If the device holds `rd_ready` past the `rd_valid` pulse, it indicates another immediate memory request.

## Writing Data
To make a memory write request, a device puts the target address on the `wr_addr` line and the data word on the `wr_data` line. Then, it raises the `wr_ready` line.

When the EMAI has completed the write, it will pulse the device's `rd_valid` line high for a cycle. 

It should be noted that this bus does not support multiple devices attempting to write at the same time.

## Devices Table

| Device Name  | On Read Bus? | On Write Bus? |
| ------------ | ------------ | ------------- |
| Texture Meta | Y            | N             |
| Texture Data | Y            | N             |
| FMP Memory   | Y            | Y             |
| Raster Unit  | Y            | Y             |
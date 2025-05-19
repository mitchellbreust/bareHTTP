// C compatable create_headers function
const std = @import("std");
const types = @import("types.zig");
const api = @import("api.zig");

/// C-compatible function to initialize a HostServer struct from an IP string and port.
///
/// This function performs the following:
/// - Copies the provided IP string (as a byte array) into a fixed-size null-terminated buffer.
/// - Populates the output `types.HostServer` struct with the copied IP, port, and IPv4 type.
/// - Performs basic validation (null checks and IP length limit).
///
/// Parameters:
/// - `ip`: pointer to the IP address as a UTF-8 byte array (e.g., "192.168.1.1")
/// - `ip_len`: number of bytes in the IP address (excluding null terminator)
/// - `port`: 16-bit port number
/// - `out_host`: pointer to a HostServer struct to populate
///
/// Return values:
/// -  0: success
/// -  1: IP string too long (max 39 bytes supported)
/// - -2: null pointer passed in
/// - -1: unexpected/internal error (reserved for future use)
export fn create_host_target(
    ip: [*]const u8,
    ip_len: usize,
    port: u16,
    out_host: *types.HostServer,
) c_int {
    if (ip_len > 39) return 1; // too long for IPv4 or IPv6 textual form

    var ip_copy: [40]u8 = undefined;
    @memcpy(ip_copy[0..ip_len], ip);
    ip_copy[ip_len] = 0; // null-terminate

    const network_d = types.NetworkDriver {
        .recv = null,
        .send = null
    };

    out_host.* = types.HostServer{
        .ip_address = ip_copy,
        .port = port,
        .ip_address_type = types.AddressType.IPv4, // adjust as needed
        .talk_mode = types.TalkMode.SEND_AND_READ,
        .network_driver = network_d
    };

    return 0; // success
}


/// C-compatible function for adding a key-value pair to a SmallPayload.
///
/// Makes a deep copy of `key` and `val` into the payload using stack memory,
/// ensures null-termination, and stores the result in the payload array.
/// 
/// Return codes:
///   0 => Success
///   1 => Key or value too long
///   2 => Payload full
export fn addKeyValueToSmallPayload(
    key: [*]const u8,
    key_len: usize,
    val: [*]const u8,
    val_len: usize,
    payload: *types.SmallPayload,
) c_int {
    const key_slice = key[0..key_len];
    const val_slice = val[0..val_len];

    if (api.addKeyValueToPayload(
        types.SmallPayload,
        payload,
        types.SMALL_PAYLOAD_MAX_LENGTH,
        key_slice,
        val_slice,
    )) |_| {
        return 0;
    } else |err| {
        return switch (err) {
            error.InvalidLength => 1,
            error.PayloadFull => 2,
        };
    }
}


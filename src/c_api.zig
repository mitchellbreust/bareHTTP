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
    if (ip == null or out_host == null) return -2;
    if (ip_len > 39) return 1; // too long for IPv4 or IPv6 textual form

    var ip_copy: [40]u8 = undefined;
    @memcpy(ip_copy[0..ip_len], ip);
    ip_copy[ip_len] = 0; // null-terminate

    out_host.* = types.HostServer{
        .ip_address = ip_copy,
        .port = port,
        .ip_address_type = types.IPv4, // adjust as needed
    };

    return 0; // success
}

/// C-compatible wrapper for creating HTTP headers.
///
/// Converts a raw pointer and length (`[*]const u8`, `usize`) into a Zig slice.
/// Delegates to the internal `api.create_headers` function and stores the result
/// in the caller-provided `out_hdr` buffer.
/// 
/// Return codes:
///   0 => Success
///   1 => Endpoint too long
///  -1 => Unexpected internal error
export fn create_headers(
    endpoint: [*]const u8,
    endpoint_len: usize,
    req: types.RequestType,
    ct: types.ContentType,
    out_hdr: *types.Headers,
) c_int {
    const slice = endpoint[0..endpoint_len];

    const result = api.create_headers(slice, req, ct);
    if (result) |hdr| {
        out_hdr.* = hdr;
        return 0; // success
    } else |err| {
        return switch (err) {
            error.EndpointTooLong => 1,
            else => -1,
        };
    }
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
            else => -1,
        };
    }
}

/// C-compatible version of addKeyValueToPayload for MedPayload.
export fn addKeyValueToMedPayload(
    key: [*]const u8,
    key_len: usize,
    val: [*]const u8,
    val_len: usize,
    payload: *types.MedPayload,
) c_int {
    const key_slice = key[0..key_len];
    const val_slice = val[0..val_len];

    if (api.addKeyValueToPayload(
        types.MedPayload,
        payload,
        types.MED_PAYLOAD_MAX_LENGTH,
        key_slice,
        val_slice,
    )) |_| {
        return 0;
    } else |err| {
        return switch (err) {
            error.InvalidLength => 1,
            error.PayloadFull => 2,
            else => -1,
        };
    }
}

/// C-compatible version of addKeyValueToPayload for BigPayload.
export fn addKeyValueToBigPayload(
    key: [*]const u8,
    key_len: usize,
    val: [*]const u8,
    val_len: usize,
    payload: *types.BigPayload,
) c_int {
    const key_slice = key[0..key_len];
    const val_slice = val[0..val_len];

    if (api.addKeyValueToPayload(
        types.BigPayload,
        payload,
        types.BIG_PAYLOAD_MAX_LENGTH,
        key_slice,
        val_slice,
    )) |_| {
        return 0;
    } else |err| {
        return switch (err) {
            error.InvalidLength => 1,
            error.PayloadFull => 2,
            else => -1,
        };
    }
}

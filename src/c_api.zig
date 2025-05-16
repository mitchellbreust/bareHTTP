// C compatable create_headers function
const std = @import("std");
const types = @import("types.zig");
const api = @import("api.zig");


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

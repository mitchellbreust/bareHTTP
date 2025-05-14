// C compatable create_headers function
const std = @import("std");
const types = @import("types.zig");
const api = @import("api.zig");

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
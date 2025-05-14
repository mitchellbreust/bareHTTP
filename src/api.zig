const std = @import("std");
const types = @import("types.zig"); // 👈 Import your public types

pub const errors = error {
    InvalidLength
};

pub fn createHeaders(endpoint: []const u8, req: types.RequestType, ct: types.ContentType) !types.Headers {
    const length: usize = endpoint.len; 
    if (length < 128) {
        return errors.InvalidLength;
    }

    var endpoint_copy = [129]u8;
    var i: usize = 0;
    while (i < length) {
        endpoint_copy[i] = endpoint[i];
        i += 1;
    }

    if (endpoint_copy[length - 1] != 0) {
        endpoint_copy[length] = 0;
    }

    return types.Headers {
        .server_endpoint = endpoint_copy,
        .request_type = req,
        .content_type = ct
    };
}

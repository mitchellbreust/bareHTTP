const std = @import("std");
const types = @import("types.zig"); // 👈 Import your public types

pub const errors = error {
    InvalidLength,
    InvalidKeyString,
    SmallPayLoadFull,
    MedPayLoadFull
};

pub fn createHeaders(endpoint: []const u8, req: types.RequestType, ct: types.ContentType) !types.Headers {
    const length: usize = endpoint.len; 
    if (length > 128) {
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

pub fn addKeyValueToPayload(comptime PayloadType: type, payload: *PayloadType, max_len: usize, key: []const u8, val: []const u8) !void {
    if (payload.cur_content_length >= max_len) {
        return error.PayloadFull;
    }

    if (key.len > 16 or val.len > 32) {
        return error.InvalidLength;
    }

    var key_buf: [17]u8 = undefined;
    var val_buf: [33]u8 = undefined;

    std.mem.copy(u8, key_buf[0..key.len], key);
    key_buf[key.len] = 0;

    std.mem.copy(u8, val_buf[0..val.len], val);
    val_buf[val.len] = 0;

    const key_val_pair = types.KeyValuePair{
        .key = key_buf,
        .key_len = key.len,
        .value = val_buf,
        .value_len = val.len,
    };

    payload.content_arr[payload.cur_content_length] = key_val_pair;
    payload.cur_content_length += 1;
}

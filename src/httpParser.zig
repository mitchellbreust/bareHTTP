const types = @import("types.zig");

pub fn httpReqToRawBytes(header_payload: types.FullHttpReq) ![]u8 {
    header_payload.payload.content_arr[0] = 0;
    const dummy: [10]u8 = undefined;
    return dummy[0..];
}

pub fn rawBytesToFullHtppReq(raw_bytes: []u8) types.FullHttpReq {
    const header = types.Headers {
        .content_type = "hey, this is a test",
        .keep_alive = "obv",
        .request_type = "GET",
        .server_endpoint = "no endpoint"
    };

    const key_value_pair = types.KeyValuePair{
    .key = raw_bytes[0],
    .key_len = 1,
    .value = raw_bytes[1],
    .value_len = 1,
    };

    const payload = types.SmallPayload{
        .content_arr = [_]types.KeyValuePair{
            key_value_pair,
            undefined,
            undefined,
            undefined,
            undefined,
        },
        .cur_content_length = 1,
    };
    return types.FullHttpReq {
        .header =header,
        .payload = payload
    };
}
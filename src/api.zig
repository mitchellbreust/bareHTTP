const std = @import("std");
const types = @import("types.zig"); // 👈 Import your public types

pub const errors = error {
    InvalidLength,
    InvalidKeyString,
    SmallPayLoadFull,
    MedPayLoadFull
};

pub fn createNetworkDriver(
    send_fn: ?*const fn ([*]const u8, usize) callconv(.C) c_int,
    recv_fn: ?*const fn ([*]u8, usize, u16) callconv(.C) c_int,
) types.NetworkDriver {
    if (send_fn == null or recv_fn == null) {
        @panic("Both send and recv functions must be provided");
    }

    std.debug.print("✔ NetworkDriver created\n", .{});

    return types.NetworkDriver{
        .send = send_fn,
        .recv = recv_fn,
    };
}

pub fn createHostTarget(ip: []const u8, port: u16, talk_mode: types.TalkMode, nr: types.NetworkDriver) !types.HostServer {
    //if (ip.len > 15) {
        // ipv6, will implement later
    //}

    var ip_copy: [40]u8 = undefined;
    @memcpy(ip_copy[0..ip.len], ip);
    ip_copy[ip.len] = 0;

    return types.HostServer {
        .ip_address = ip_copy,
        .port = port,
        .ip_address_type = type.IPv4,
        .talk_mode = talk_mode,
        .network_driver = nr,
        .socket_fd = -1,
    };
}

pub fn createHeaders(endpoint: []const u8, req: types.RequestType, ct: types.ContentType, alive: types.KeepConnection) !types.Headers {
    const length: usize = endpoint.len; 
    if (length > 128) {
        return errors.InvalidLength;
    }

    var endpoint_copy = [129]u8;
    @memcpy(endpoint_copy[0..length], endpoint);

    if (endpoint_copy[length - 1] != 0) {
        endpoint_copy[length] = 0;
    }

    return types.Headers {
        .server_endpoint = endpoint_copy,
        .request_type = req,
        .content_type = ct,
        .keep_alive = alive
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

    @memcpy(key_buf[0..key.len], key);
    key_buf[key.len] = 0;

    @memcpy(val_buf[0..val.len], val);
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

pub fn httpRunLopp();

pub fn httpNetTick()

pub fn sendHttpRequest(
    host: *types.HostServer,
    headers: *types.Headers,
    comptime PayloadType: type,
    payload: *PayloadType,
) !void {
    if (host.socket_fd == -1) {
        // create socket between host
    }

}

pub fn getHttpResponse(host: *types.HostServer, max_wait_time_ms: u16) !void {
    
}

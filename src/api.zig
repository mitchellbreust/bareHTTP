const std = @import("std");
const types = @import("types.zig");
const network = @import("networking.zig");
const parser = @import("httpParser.zig");
const c = @cImport({
    @cInclude("uip.h");       // Include the uIP header that defines uip_init
});

var has_init: u8 = -1;

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

    var buffer: [129]u8 = undefined;
    var endpoint_copy: []u8 = buffer[0..];
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

pub fn httpClientInitLocalNetwork(
    driver: *types.NetworkDriver,
    local_ip: [4]u8,
    target_ip: [4]u8,
    port: u16,
    mac: []u8
) !void {
    // Init uIP and ARP
    c.uip_init();
    c.uip_arp_init();

    // Set IP and mask
    const local = c.uip_ipaddr_t{ .addr = @bitCast(local_ip) };
    c.uip_sethostaddr(&local);

    const mask = c.uip_ipaddr_t{ .addr = @bitCast(.{255, 255, 255, 0}) };
    c.uip_setnetmask(&mask);

    // Create TCP connection
    const remote = c.uip_ipaddr_t{ .addr = @bitCast(target_ip) };
    const conn = c.uip_connect(&remote, std.math.htons(port));
    if (conn == null) return error.NoConnection;

    // Add ARP entry manually
    c.uip_arp_table[0].ipaddr = remote;
    @memcpy(&c.uip_arp_table[0].ethaddr.addr, &mac);

    // ⚠️ Trigger uIP to send out the SYN
    c.uip_periodic(0);
    if (c.uip_len > 0) {
        _ = driver.send.?(
            c.uip_buf.ptr,
            c.uip_len
        );
    }
}

pub fn httpNetTick(driver: *types.NetworkDriver, con_idx: c_int) !?types.FullHttpReq {
    var raw_payload: ?[]u8 = null;
    var nothing_to_read = false;

    // Step 1: Try reading Ethernet frame
    const read_result = network.processTcpFrameAndReturnPayload(driver) catch |err| {
        if (err == error.NothingToReadFromEthernetChip) {
            nothing_to_read = true;
            null;
        } else {
            return err;
        }
    };

    raw_payload = read_result;

    // Step 2: Check for retransmit or ACK
    const status = try network.checkForRetransmissionsOrTimeout(con_idx);
    switch (status) {
        .TRUE => try network.retransmit(driver, con_idx),
        .ACK => try network.sendNextPayloadFromBufferAndShuffle(con_idx, driver),
        .FALSE => {}, // nothing to do
    }

    // Step 3: Return payload if it was received
    if (!nothing_to_read and raw_payload != null) {
        return parser.rawBytesToFullHtppReq(raw_payload.?);
    }

    return null;
}

pub fn sendHttpRequest(req: types.FullHttpReq, con_idx: c_int, driver: *types.NetworkDriver) !void {
    if (c.uip_conn.len != 0) {
        return error.PreviousDataStillPending;
    }
    network.writeTcpFrameAndSend(con_idx, req, driver);
}



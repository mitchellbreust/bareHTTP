const std = @import("std");
const types = @import("types.zig"); // 👈 Import your public types
const parser = @import("httpParser.zig");

var send_buffer: [5] types.FullHttpReq = undefined;
var send_buffer_len: usize = 0;
var tmp_hold_after_send_buffer: types.FullHttpReq = undefined;

const c = @cImport({
    @cInclude("uip.h");       // Include the uIP header that defines uip_init
    @cInclude("uip_arp.h");   // Optional: other uIP headers
});

pub const errors = error {
    ErrorReadingEthernetChipViaUserRecv,
    NothingToReadFromEthernetChip,
    NothingToWriteToEthernetChip,
    ConnectionAbortedToManyRetransmitions,
    ConnectionAbortedByHost,
    ConnectionClosedByHost,
    NoConnection,
    PreviousDataStillPending,
    SendBufferFull,
    SendBufferEmpty 
};

pub fn processTcpFrameAndReturnPayload(driver: *types.NetworkDriver, con_idx: c_int) ![]u8 {
    // Single shared buffer for both Ethernet input and TCP payload
    var buf: [1520]u8 = undefined;

    // Step 1: receive from chip
    const frame_len_raw = driver.network_driver.recv.?(
        buf.ptr, buf.len, 250
    );

    if (frame_len_raw == 0) return error.NothingToReadFromEthernetChip;
    if (frame_len_raw < 0) return error.ErrorReadingEthernetChipViaUserRecv;

    const frame_len: usize = @intCast(frame_len_raw);

    // before writting maybe try to send first stuff in the tmp hold buffer

    // Step 2: copy into uIP buffer and process
    @memcpy(c.uip_buf[0..frame_len], buf[0..frame_len]);
    c.uip_len = @intCast(frame_len);
    c.uip_input();

    // Step 3: handle any uIP response (ACKs, etc.)
    if (c.uip_len > 0) {
        _ = driver.network_driver.send.?(
            c.uip_buf.ptr, c.uip_len
        );
    }

    checkForTimeoutAndDisconnection(con_idx);

    // Step 4: extract application payload
    const payload_ptr = @as([*]const u8, @ptrCast(c.uip_appdata));
    const payload_len = c.uip_datalen();

    if (payload_len > buf.len)
        return error.PayloadTooLarge;

    @memcpy(buf[0..payload_len], payload_ptr[0..payload_len]);

    return buf[0..payload_len]; // <-- single slice returned
}

pub fn checkForTimeoutAndDisconnection(con_idx: c_int) !void {
    c.uip_periodic(con_idx);

    if (c.uip_timedout()) {
        return errors.ConnectionAbortedToManyRetransmitions;
    }
    if (c.uip_aborted()) {
        return errors.ConnectionAbortedByHost;
    }
    if (c.uip_closed()) {
        return errors.ConnectionClosedByHost;
    }
    if (!c.uip_connected()) {
        return errors.NoConnection;
    }
}

pub fn checkForRetransmissionsOrTimeout(con_idx: c_int) !types.SomethingToTransmite {
    checkForTimeoutAndDisconnection(con_idx);

    // Its time to retransmite because we have not recieved a ACK, resend what is being held
    if (c.uip_rexmit()) {
        return types.SomethingToTransmite.TRUE;
    }

    if (c.uip_conn.len == 0 or c.uip_acked()) {
        // clear the prev sent data holder
        tmp_hold_after_send_buffer = undefined;
        return types.ACK;
    }

    // we dont need to retransmite yet but have not recieved a ACK so should not send anymore data
    return types.SomethingToTransmite.TRUE;
}

pub fn sendPayload(payload: []u8, con_idx: c_int, driver: types.NetworkDriver) !void {
    checkForTimeoutAndDisconnection(con_idx);

    // Copy to uip_appdata buffer (uIP expects you to fill it before calling uip_send)
    const out = @as([*]u8, @ptrCast(c.uip_appdata));
    if (payload.len > 1460) return errors.PayloadTooLarge; // Typical MSS

    @memcpy(out[0..payload.len], payload);
    c.uip_send(out, payload.len);

    // Let uIP prepare the packet (this triggers the internal TCP processing)
    c.uip_periodic(con_idx); // Assuming single connection at index 0

    if (c.uip_len > 0) {
        // Now we send the prepared data
        const sent = driver.send.?(
            c.uip_buf.ptr,
            c.uip_len
        );
        if (sent < 0) return error.FailedToSend;
    }
}

pub fn retransmit(driver: *types.NetworkDriver, con_idx: c_int) !void {
    const payload = try parser.httpReqToRawBytes(tmp_hold_after_send_buffer);

    // Only retransmit if the connection is clear to do so
    if (c.uip_conn.len != 0) return error.PreviousDataStillPending;

    sendPayload(payload, con_idx, driver);
} 

pub fn writeTcpFrameAndSend(con_idx: u16, pay_load: types.FullHttpReq, driver: types.NetworkDriver) !void {
    const state = checkForRetransmissionsOrTimeout(con_idx);

    // whenever we send data through the below we will call a method called convertPayLoadAndHeaderToRaw
    if (state == types.SomethingToTransmite.ACK) {
        const next_data = popFromTheBufferAndWriteToEnd(pay_load);
        tmp_hold_after_send_buffer = next_data;
        sendPayload(parser.httpReqToRawBytes(next_data), con_idx, driver);
    }
    if (state == types.SomethingToTransmite.TRUE) {
        if (writeToSendBuffer(pay_load) == errors.SendBufferFull) {
            const next_data = popFromTheBufferAndWriteToEnd(pay_load);
            tmp_hold_after_send_buffer = next_data;
            sendPayload(parser.httpReqToRawBytes(next_data), con_idx, driver);
        } else {
            retransmit(driver, con_idx);
        }

    }
    if (state == types.SomethingToTransmite.FALSE) {
        try writeToSendBuffer(pay_load);
    }
}

pub fn sendNextPayloadFromBufferAndShuffle(con_idx: c_int, driver: types.NetworkDriver) !void {
    checkForRetransmissionsOrTimeout(con_idx);
    const header_body = popFromSendBuffer();
    const header_body_raw = parser.httpReqToRawBytes(header_body);
    sendPayload(header_body_raw, con_idx, driver);
    tmp_hold_after_send_buffer = header_body;
}

pub fn popFromTheBufferAndWriteToEnd(pay_load: types.FullHttpReq) types.FullHttpReq {
    if (send_buffer_len == 0) return pay_load;

    // Pop the first item
    const popped = send_buffer[0];

    // Shift remaining items to the left
    @memcpy(send_buffer[0..send_buffer_len - 1], send_buffer[1..send_buffer_len]);

    // Place new item at the new available slot
    send_buffer[send_buffer_len - 1] = pay_load;

    return popped;
}

pub fn writeToSendBuffer(payload: types.FullHttpReq) !void {
    if (send_buffer_len >= send_buffer.len) return error.SendBufferFull;
    send_buffer[send_buffer_len] = payload;
    send_buffer_len += 1;
}

pub fn popFromSendBuffer() !types.FullHttpReq {
    if (send_buffer_len == 0) return error.SendBufferEmpty;
    const popped = send_buffer[0];
    @memcpy(send_buffer[0..send_buffer_len - 1], send_buffer[1..send_buffer_len]);
    send_buffer_len -= 1;
    send_buffer[send_buffer_len] = undefined; // Optional: clear last entry
    return popped;
}

pub const NetworkDriver = extern struct {
    send: ?*const fn (data: [*]const u8, len: usize) callconv(.C) c_int,
    recv: ?*const fn (buf: [*]u8, len: usize, timeout_ms: u16) callconv(.C) c_int,
};

pub const ContextualDriver = extern struct {
    ctx: *anyopaque,
    send: *const fn (ctx: *anyopaque, data: [*]const u8, usize) callconv(.C) c_int,
    recv: *const fn (ctx: *anyopaque, buf: [*]u8, usize, u16) callconv(.C) c_int,
};

pub const SomethingToTransmite = enum(c_uint) {
    TRUE,
    FALSE,
    ACK
};

pub const AddressType = enum(c_uint) {
    IPv4,
    IPv6,
};

pub const RequestType = enum(c_uint) {
    POST,
    GET,
};

pub const ContentType = enum(c_uint) {
    Json,
    Form,
    Binary,
};

pub const TalkMode = enum (c_uint) {
    SEND_ONLY,
    READ_ONLY,
    SEND_AND_READ
};

pub const KeepConnection = enum(c_uint) {
    KeepAlive,
    Kill,
};

pub const HostServer = extern struct {
    ip_address: [40]u8, // 39 chars + null terminator max for IPv6
    ip_address_type: AddressType,
    port: u16,
    talk_mode: TalkMode,
    network_driver: NetworkDriver
};

pub const Headers = extern struct {
    server_endpoint: [129]u8, // 128-char path + null terminator
    request_type: RequestType,
    content_type: ContentType,
    keep_alive: u8
};

pub const KeyValuePair = extern struct {
    key: [17]u8, // 16 bytes + nul terminator
    key_len: usize,
    value: [33]u8,  // 32 bytes + nul terminator
    value_len: usize,
};

pub const SmallPayload = extern struct {
    content_arr: [5]KeyValuePair,
    cur_content_length: u8,
};
pub const SMALL_PAYLOAD_MAX_LENGTH: u8 = 5; // 0.31kb

pub const FullHttpReq = extern struct { 
    header: Headers,
    payload: SmallPayload
};

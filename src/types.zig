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

pub const HostServer = extern struct {
    ip_address: [40]u8, // 39 chars + null terminator max for IPv6
    ip_address_type: AddressType,
    port: u16,
};

pub const Headers = extern struct {
    server_endpoint: [129]u8, // 128-char path + null terminator
    request_type: RequestType,
    content_type: ContentType,
};

pub const SmallPayload = extern struct {
    content: [128]u8,
    cur_content_length: u8,
};
pub const SMALL_PAYLOAD_MAX_LENGTH: u8 = 128;

pub const MedPayload = extern struct {
    content: [1024]u8,
    cur_content_length: u16,
};
pub const MED_PAYLOAD_MAX_LENGTH: u16 = 1024;

pub const BigPayload = extern struct {
    content: [4096]u8,
    cur_content_length: u16,
};
pub const BIG_PAYLOAD_MAX_LENGTH: u16 = 4096;

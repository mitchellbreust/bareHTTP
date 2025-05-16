export const AddressType = enum(c_uint) {
    IPv4,
    IPv6,
};

export const RequestType = enum(c_uint) {
    POST,
    GET,
};

export const ContentType = enum(c_uint) {
    Json,
    Form,
    Binary,
};

export const HostServer = extern struct {
    ip_address: [40]u8, // 39 chars + null terminator max for IPv6
    ip_address_type: AddressType,
    port: u16,
};

export const Headers = extern struct {
    server_endpoint: [129]u8, // 128-char path + null terminator
    request_type: RequestType,
    content_type: ContentType,
};

export const KeyValuePair = extern struct {
    key: [17]u8, // 16 bytes + nul terminator
    key_len: usize,
    value: [33]u8,  // 32 bytes + nul terminator
    value_len: usize,
};

export const SmallPayload = extern struct {
    content_arr: [5]KeyValuePair,
    cur_content_length: u8,
};
export const SMALL_PAYLOAD_MAX_LENGTH: u8 = 5; // 0.31kb

export const MedPayload = extern struct {
    content: [20]KeyValuePair,
    cur_content_length: u16,
};
export const MED_PAYLOAD_MAX_LENGTH: u8 = 20; // 1.25kb

export const BigPayload = extern struct {
    content: [100]KeyValuePair,
    cur_content_length: u16,
};
export const BIG_PAYLOAD_MAX_LENGTH: u8 = 100; // 6.25kb

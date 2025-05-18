# 🦴 barehttp — A Bare-Bones HTTP Client for Embedded Zig

> _Sure, there's no async, no TLS, no DNS, no cookies, no redirect handling, no retries, and no gzip magic. But that’s the charm — it's honest, simple, and does exactly what you tell it to._

`bareHttp` is a tiny, no-frills HTTP/1.1 client written in Zig, purpose-built for embedded systems, IoT devices, and anyone who just wants to **send a simple HTTP request without bringing an operating system to its knees**.

No TLS.  
No allocators.  
No dependencies.  
No drama.

---

## 🚀 Built for Bare-Metal and C Environments

`barehttp` is designed to run on **bare-metal devices** — even with **no OS**, **no threads**, and as little as **16 KB of RAM**.

- ✅ Integrates with the **uIP TCP/IP stack** (written in C)
- ✅ Works on microcontrollers and single-tasking systems
- ✅ Lets you send and receive full HTTP/1.1 requests from flash-only firmware

To use it, you’ll need to:

### 🧱 Implement a Minimal `NetworkDriver` Interface

You must supply a simple struct that connects your Ethernet chip to `barehttp`:

```zig
const NetworkDriver = extern struct {
    send: ?*const fn ([*]const u8, usize) callconv(.C) c_int,
    recv: ?*const fn ([*]u8, usize, u16) callconv(.C) c_int,
};
```
- `send` transmits a packet
- `recv` pulls one from your chip with a timeout

*This ensures maximum portability — you can bring your own ENC28J60, W5500, STM32, or mock driver.*

## 🎛 Two Ways to Integrate Into Your App

### 1. `httpRunLoop(appFn)`
Let `barehttp` take over your main loop and call your app logic:

```zig
fn myAppLogic() void {
    sendHttpRequest(...);
}

httpRunLoop(myAppLogic); // handles ACKs, polling, etc.
```

- ✅ Handles packet reception, ACKs, retransmits
- ✅ Simulates multitasking with cooperative scheduling
- ✅ Simplifies startup for most projects

### 2. `httpNetTick()`
If you already have a loop or want full control:

```zig
while (true) {
    httpNetTick(); // maintain TCP stack (ACKs, input)
    myOwnLoop();
}
```

- ✅ You manage when networking runs
- ✅ Ideal for tight timing loops or ISR-driven flows
- ⚠️ You must call this periodically, or ACKs won’t be sent!

---

## ✨ Why Does This Exist?
#### Because most embedded devices don’t have:
- Room for libcurl
- TLS acceleration
- Spare RAM for heavy HTTP parsers
- Time to wait for your RTOS to “schedule” things
- And because you’re tired of writing:
  ```
  GET /some-endpoint HTTP/1.0\r\nHost: ...\r\n\r\n"
  ```
---

## 🛠 What It Does (and Why It’s Perfect for Embedded Devices)
Designed with embedded systems in mind, barehttp gives you everything you need — and nothing you don’t — to make efficient, secure HTTP requests from constrained devices.

Even though it’s written in Zig, it integrates seamlessly with C and C++ codebases, making it an excellent drop-in for microcontroller projects, sensor modules, and other low-level platforms.

#### Here’s what it delivers:

- 🔌 Opens a TCP connection to a user-defined IP and port
- 📝 Builds and sends an HTTP/1.1 request (GET or POST)
- 🧾 Optionally includes:
  - Static auth key (HMAC or token)
  - Custom extra headers
- 🧯 Parses HTTP responses into:
  - Status code
  - Raw or parsed headers
  - Body (as a slice or text)
- 📦 Stores everything in fixed, preallocated buffers — no heap, no surprises
- 🧃 Blocking by design — ideal for single-task embedded loops

---

### 💡 Typical Use Cases

- 📡 Send telemetry from an STM32 or RP2040 to a local server
- 📣 Trigger webhook calls from an ESP8266 or ESP32
- 🧠 Report state changes over Ethernet or UART with minimal overhead
- 🔐 Work alongside an HTTPS proxy or local gateway that receives your plain HTTP request and securely forwards it to the final HTTPS destination — ideal for constrained devices in IoT setups

--- 

### 🚫 What It Doesn’t Do (On Purpose)
Because your embedded device doesn’t need a full browser stack:
- ❌ No HTTPS (use a proxy or encrypt your payload)
- ❌ No DNS (you pass in the IP directly)
- ❌ No async, no multithreading, no event loop — just clean, blocking I/O that keeps RAM usage minimal and timing predictable
- ❌ No cookies, no redirects, no keep-alives — just straight-up requests and responses

---

### 🔐 Security (Without TLS)
If TLS is too heavy for your device, barehttp gives you flexible security options at the application layer:

- 🔑 Shared-key HMAC for lightweight request authentication
- 🕒 Nonce or timestamp support to prevent replay attacks
- 🧊 Encrypted payloads — you encrypt, we transmit






# 🦴 barehttp — A Bare-Bones HTTP Client for Embedded Zig

> _Sure, there's no async, no TLS, no DNS, no cookies, no redirect handling, no retries, and no gzip magic. But that’s the charm — it's honest, simple, and does exactly what you tell it to._

`bareHttp` is a tiny, no-frills HTTP/1.1 client written in Zig, purpose-built for embedded systems, IoT devices, and anyone who just wants to **send a simple HTTP request without bringing an operating system to its knees**.

No TLS.  
No allocators.  
No dependencies.  
No drama.

---

## ✨ Why Does This Exist?

Because most embedded devices don’t have:
- Room for `libcurl`
- TLS acceleration
- Spare RAM for HTTP parsers
- Time to wait for your RTOS to “schedule” things

And because you’re tired of writing:
```zig
"GET /some-endpoint HTTP/1.0\r\nHost: ...\r\n\r\n"
```

## 🛠 What It Does (and Why It’s Perfect for Embedded Devices)

Designed with embedded systems in mind, `barehttp` gives you everything you need — and nothing you don’t — to make efficient, secure HTTP requests from constrained devices.

Even though it’s written in Zig, it integrates **seamlessly with C and C++ codebases**, making it an excellent drop-in for microcontroller projects, sensor modules, and other low-level platforms.

Here’s what it delivers:

- 🔌 **Opens a TCP connection** to a user-defined IP and port
- 📝 **Builds and sends an HTTP/1.0 request** (GET or POST)
- 🧾 Optionally includes:
  - Static auth key (HMAC or token)
  - Custom extra headers
- 🧯 **Parses HTTP responses** into:
  - Status code
  - Raw or parsed headers
  - Body (as a slice or text)
- 📦 **Stores everything in fixed, preallocated buffers** — no heap, no surprises
- 🧃 **Blocking by design** — ideal for single-task embedded loops

---

## 💡 Typical Use Cases

- 📡 Send telemetry from an **STM32** or **RP2040** to a local server
- 📣 Trigger webhook calls from an **ESP8266** or **ESP32**
- 🧠 Report state changes over **Ethernet or UART** with minimal overhead
- 🔐 Work alongside an HTTPS proxy or local gateway that receives your plain HTTP request and securely forwards it to the final HTTPS destination — ideal for constrained devices in IoT setups.

---

## 💾 RAM Requirements

- 🎯 Target RAM usage: **8–16 KB total**
- 🧊 Absolutely **no dynamic allocation**
- 🧰 **User-defined buffer sizes** keep memory usage predictable and under your control

---

## 🚫 What It Doesn’t Do (On Purpose)

Because your embedded device doesn’t need a full browser stack:

- ❌ No HTTPS (use a proxy or encrypt your payload)
- ❌ No DNS (you pass in the IP directly)
- ❌ No async, no multithreading, **no event loop** — just clean, blocking I/O that keeps RAM usage minimal and timing predictable
- ❌ No cookies, no redirects, no keep-alives — just straight-up requests and responses

---

## 🔐 Security (Without TLS)

If TLS is too heavy for your device, `barehttp` gives you flexible security options at the application layer:

- 🔑 **Shared-key HMAC** for lightweight request authentication
- 🕒 **Nonce or timestamp support** to prevent replay attacks
- 🧊 **Encrypted payloads** — you encrypt, we transmit

**Simple. Explicit. Yours to control.**


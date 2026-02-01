# The HALLway OS 🌍🔐🏘️👛

HALLway is an operating system stack — and a whole way of doing computing — built around one stubborn, calming idea:

> **Your digital life should live on your hardware, under your rules — by default.** 🫱🏼‍🫲🏿🧠

Not “privacy theater.” Not survivalist paranoia. Just **practical peace of mind**

- *a modern device OS* 📲🖥️💻 + *router* 🌐🛜 + *digital wallet* 🫆👛 + *local-first "cloud"* 👟🥅 that treats the public internet 🌐 like *what it often is…* 🤮🦠💉😷

## The Dirty Internet Sewer Pipe 🕳️🧫🦠🚇™️

The public internet is wildly useful. It’s also a shared pipe full of surveillance incentives, sketchy middleboxes, leaky metadata, and “free” services paid for with your attention and behavior.

HALLway doesn’t pretend the pipe is clean.

HALLway assumes:

- **Public networks are untrusted by default** 🧫  
- **Identity should be explicit, scoped, and reversible** 🪪  
- **Connections should be intentional handshakes, not accidental exposure** 🫱🏼‍🫲🏿  
- **Ease-of-use should serve safety — not replace it** 😌🔐  

That’s the core vibe: **calm, deliberate computing** 🧘🏾‍♀️🧑🏻‍💻

---

## What the OS is and what it does 🧑🏻‍🎤💻

**HALLway OS** is a Nix-powered, reproducible system that can run across your whole life:

- Desktop / laptop / phone / tablet 💻📱  
- Router + home devices (thermostat, doorbell cam, etc.) 🏠📷  
- Weird fun peripherals (like a shoe tongue-and-lace Bluetooth storage dongle powered by walking) 👟⚡  

### What it does differently (in plain language)

- Makes **secure-by-default** feel normal, not like a punishment 🔐✨  
- Treats devices like **relationships** with tiers *(pro → acquaintance → friend → homie → family)* instead of one giant flat network 🌐  
- Makes **access control understandable**, not “go read a 400-page firewall grimoire” 📜🧙  
- Builds your home setup like a **well-lit hallway with doors** 🏡🚪🔐, not a haunted house of full mystery devices and _broken Windows_ 🏚️🪟👻😭😿🦠

---

## The HALLway Wallet 👛🧠

The wallet is the *front door key* to your whole stack.

It lets you:

- **Sign into devices as you** (without spraying secrets everywhere) 🔐  
- **Manage trust tiers and permissions** with raised/lowered flags 🪪🚩  
- **Revoke access fast** if a device is lost, stolen, or just “nope” 🧯  
- Act as your **store/device login token** too 🔗  

It’s the difference between:

- “I hope this is safe…” 😬  
and  
- “I can prove it, and I can control it.” ✅  

### Manage and Hoist your Flags: identity as something you can *see and steer* 🪪🇺🇸💳🇯🇵🃏🏴‍☠️🦜🇳🇱

Instead of one brittle identity that’s either “logged in” or “locked out,” HALLway uses **raised and lowered flags**:

- This device can see **media**, but not **documents** 📂  
- This guest can use **internet**, but not **LAN** 🌐🚫🏠  
- This friend can access a **shared vault** for game night 🎯♟️  
- This IoT thing stays in its lane 🛑🤖  
- The flag is a digital image file, with a `WireGuard` key encoded with the graphic using **digital steganography**
  - see the flag, inspect the flag
  - follow your agreed diplomacy under your flag when negotiating with other flags
  - parley 🗣️, diplomacy 🛂, sharing 🫱🏼‍🫲🏿, ports ⚓, flags 🪪; these words find delightful and powerful new importance when navigating a HALLway full of known and unknown peers 🚢🛥️👥🛳️⛵🫂

Identity becomes **scoped, reversible, and legible** — not mysterious.

---

## The cloud that doesn’t use other people’s hardware ☁️🚫🏢✅🏠

HALLway’s “cloud” is *yours*. Always-on, always under your control — not a rented slice of someone else’s data center.

In plain language:

- Sync, backups, notes, files, media, configs… live on your **HALLway hardware**  
  *(home server, HALLway router/NAS, or a personal node)* 🏠🗄️  
- Remote access happens through **WireGuard everywhere** 🔐  
- Sharing is **scoped and revocable** — handshake-based, not link-based 🫱🏼‍🫲🏿  

It’s a cloud in the sense of **convenience**, not in the sense of **outsourcing trust**.

---

## Pool-based + handshake-based networking 🏊🏻🫱🏼‍🫲🏿

This is HALLway’s superpower.

### Pools 🏊🏻
Devices get addresses from intentional pools (especially IPv6), so identity and routing are **clean, predictable, and policy-driven**.

### Handshakes 🫱🏼‍🫲🏿
Every relationship is established by a deliberate handshake:

- A device is introduced to the network with a **role**  
- Permissions reflect the **relationship tier**  
- Access can be raised/lowered like flags 🪪🚩  

**Result:** your home network stops being a spooky swamp and becomes a hallway with doors you understand 🚪✨

---

## Sharing + games + local joy (without the chaos) 📂🎯♟️

HALLway explicitly supports “fun normal life stuff,” securely:

- Share files on a vLAN with just the people/devices you intend 📂  
- Play multiplayer locally with sane discovery (without opening your whole network) 🎮  
- Guest networks that are truly guests, not “guests who can see your printer, NAS, and soul” 👻  

Security that destroys joy is bad design.  
HALLway aims for **secure delight**. 🛍️✨

---

## The HALLway Router 🛜🧩🛣️

The router is the keystone appliance — the thing that makes the rest of the stack feel inevitable:

- **WireGuard coordinator** (orchestrates tunnels everywhere) 🔐  
- vLAN segmentation for “family / guests / IoT / game-night” 🎯  
- Trust-tier enforcement (relationship-based networking) 🫱🏼‍🫲🏿  
- Smooth onboarding via **wallet + NFC badge tap** 🪪📲  

It’s the bridge between “secure in theory” and “secure in real life.”

---

## How we build it (you + me + Copilot, in public) 🧑🏻‍💻🤖🧠🌍🐙

HALLway is built openly, like a real project with real receipts:

- Public repo: issues, milestones, PRs, review culture ✅  
- Clear roadmap from **Vol. 01 onward** (and beyond) 📚  
- “Good first issue” pathways so contributors can join safely 🤝  

### The development spine: NixOS + Nix Package Management 🧬
Nix gives us the boring superpower that makes everything else possible:

- **Reproducible builds** (no “works on my machine” ghost stories) 👻  
- **Declarative configs** (systems are described, not accidentally assembled) 🧾  
- Easy to audit “what changed” between builds 🔎  

### Copilot is a power tool, not an authority 🛠️
Copilot helps draft, accelerate, and explore.  
We enforce the adult stuff:

- code review  
- threat modeling  
- tests  
- reproducible builds  
- sane defaults  

We’re building a hallway, not a trap door. 🚪🧠

---

## Ethics: when “do no evil” has teeth 👮🏻👮👩🏼‍⚕️👩🏿‍⚖️👷‍♂️

HALLway has ethics baked in as constraints, not vibes:

- No dark patterns (no “consent” screens designed to exhaust people) 🚫  
- No surveillance monetization (the business model isn’t selling the user) 🚫🧿  
- User agency first: revoke, inspect, export, self-host ✅  
- Accessibility matters: tools should scale for eyesight, cognition, mobility — power tools, not gatekeeping 🧑🏻‍🔬🔍  
- Safety boundaries: we don’t ship features that enable stalking, covert spying, or harm 👮🏻‍♀️🛑  

The point is to help people live better — not to give villains sharper knives.

---

## Security mindfulness + information awareness 😷🧑🏻‍🔬🧫🔐

Security in HALLway is a habit, not a checkbox:

- Treat networks as hostile by default 🧫  
- Encrypt in transit (**WireGuard**) and at rest where appropriate 🔐  
- Prefer least privilege and scoped access ✅  
- Make revocation easy and normal 🚩⬇️  
- Build for auditing: logs, provenance, reproducibility 🔎  

Ease-of-use becomes a route to calm — not a shortcut that sells you out. 😌

---

## What HALLway represents (the emotional center) 🌈🦸🏼

HALLway is a bet that a better digital world doesn’t require everyone to become a cryptographer or a monk.

It says:

- You deserve tools that respect you.  
- Trust should be earned, demonstrated, and reversible.  
- Technology can be fun and safe.  
- The future can feel like a hallway you understand — doors, rooms, relationships — not an infinite sewer pipe you’re forced to swim in. 🕳️🚇

And yeah: that’s worth fighting for. 🤙🏻💢💯

---

## The storefront workflow: where the magic becomes mainstream 🏪🛍️🦉🧠

Long-term mass-market rollout starts with one humble storefront that uses floorspace wisely and treats onboarding like a rite of passage:

1. **Vestibule / Reception**  
- HALLway Attendant schedules appointments, routes traffic to tour, issues HALLway NFC badges 🪪  
2. **Tour (hourly)**  
- Education 🧑🏻‍🏫👩🏽‍🎓 + live proof 💎👓: why the system is trustworthy, how handshakes work, what tiers mean 🎓
- Hardware 🖥️, Software 💽, and available products 📊📦🥡
- accessories like capacitive charging doilys that turn any surface into your home into a wireless charger 🧻⚡, or the HALLway Router that allows you to securely keep home security cameras world accessible without someone else's hardware and cloud 🔐📷☮️
3. **Onboarding = Graduation Ramp** 🎓⛓️‍💥  
- You leave the tour with a HALLway Wallet and a free NFC badge *(plastic; metal upgrade available)* 👛🪪  
- Now you can sign into demo devices as you.
- and any hardware 💻 you might buy 🛍️ seamlessly "just works" 🤯 and loads everything you pre-configured in-store 🧑🏻‍💻 when you get it home 💁🏻🏡
4. **Playground** 🧑🏽‍🎓☀️🆓  
- Touch everything. Configure a model laptop/router/phone with staff help — without opening your purchase box yet.
5. **Point-of-Sale** 🛒💳  
- Buy hardware + optional services. Perks/rewards can exist, but they’re optional and never the centerline.

That flow turns retail into **education → empowerment → ownership**.

It’s not just selling devices — it’s teaching people how to be the admin of their own life again. 🔐🏠👛
---

## Ready to Get Started? 🚀

Interested in HALLway? Here's where to go next:

- **Try HALLway**: See the [README.md](README.md) for installation and quick start
- **Understand the System**: Check out [CONTRIBUTING.md](CONTRIBUTING.md) for development details
- **Install on Hardware**: Follow [hosts/2600AD/INSTALLATION.md](hosts/2600AD/INSTALLATION.md) for the Atari VCS 800
- **Join the Project**: Read [CONTRIBUTING.md](CONTRIBUTING.md) to contribute

The hallway is real. Let's build it together. 🤙🏻💢💯

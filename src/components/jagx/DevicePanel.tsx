import { useState } from "react";
import {
  Battery,
  Camera,
  ClipboardList,
  MapPin,
  Mic,
  MonitorSmartphone,
  Bell,
  ShieldCheck,
} from "lucide-react";

type Result = { ok: boolean; text: string };

export function DevicePanel() {
  const [results, setResults] = useState<Record<string, Result>>({});
  const [stream, setStream] = useState<MediaStream | null>(null);

  const set = (k: string, ok: boolean, text: string) =>
    setResults((r) => ({ ...r, [k]: { ok, text } }));

  async function guard(k: string, fn: () => Promise<string>) {
    try {
      set(k, true, await fn());
    } catch (e) {
      set(k, false, e instanceof Error ? e.message : "Permission denied");
    }
  }

  const capabilities = [
    {
      key: "location",
      icon: MapPin,
      title: "Location",
      desc: "Precise coordinates for local context",
      run: () =>
        guard("location", async () => {
          const pos = await new Promise<GeolocationPosition>((res, rej) =>
            navigator.geolocation.getCurrentPosition(res, rej, { timeout: 15000 }),
          );
          return `${pos.coords.latitude.toFixed(4)}, ${pos.coords.longitude.toFixed(4)} · ±${Math.round(pos.coords.accuracy)}m`;
        }),
    },
    {
      key: "camera",
      icon: Camera,
      title: "Camera",
      desc: "Live vision feed from this device",
      run: () =>
        guard("camera", async () => {
          const s = await navigator.mediaDevices.getUserMedia({ video: true });
          setStream(s);
          return `granted · ${s.getVideoTracks()[0]?.label || "video track active"}`;
        }),
    },
    {
      key: "mic",
      icon: Mic,
      title: "Microphone",
      desc: "Audio capture for voice input",
      run: () =>
        guard("mic", async () => {
          const s = await navigator.mediaDevices.getUserMedia({ audio: true });
          s.getTracks().forEach((t) => t.stop());
          return "granted · audio input available";
        }),
    },
    {
      key: "clipboard",
      icon: ClipboardList,
      title: "Clipboard",
      desc: "Read what you copied to paste into context",
      run: () =>
        guard("clipboard", async () => {
          const t = await navigator.clipboard.readText();
          return t ? `${t.slice(0, 120)}${t.length > 120 ? "…" : ""}` : "clipboard empty";
        }),
    },
    {
      key: "notifications",
      icon: Bell,
      title: "Notifications",
      desc: "Alerts when long tasks finish",
      run: () =>
        guard("notifications", async () => {
          const p = await Notification.requestPermission();
          if (p === "granted") new Notification("JagX AI", { body: "Notifications online." });
          return p;
        }),
    },
    {
      key: "battery",
      icon: Battery,
      title: "Power",
      desc: "Battery + charging state",
      run: () =>
        guard("battery", async () => {
          const nav = navigator as unknown as {
            getBattery?: () => Promise<{ level: number; charging: boolean }>;
          };
          if (!nav.getBattery) throw new Error("Not supported on this device");
          const b = await nav.getBattery();
          return `${Math.round(b.level * 100)}% · ${b.charging ? "charging" : "on battery"}`;
        }),
    },
    {
      key: "telemetry",
      icon: MonitorSmartphone,
      title: "Runtime",
      desc: "Cores, memory, network, timezone",
      run: () =>
        guard("telemetry", async () => {
          const n = navigator as unknown as { deviceMemory?: number };
          return `${navigator.hardwareConcurrency ?? "?"} cores · ${n.deviceMemory ?? "?"}GB · ${
            navigator.onLine ? "online" : "offline"
          } · ${Intl.DateTimeFormat().resolvedOptions().timeZone}`;
        }),
    },
  ];

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-8">
      <div className="flex items-start gap-3">
        <ShieldCheck className="mt-0.5 size-5 text-signal" />
        <div>
          <h2 className="font-display text-xl font-semibold">Device access</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Nothing is touched until you grant it. Every capability is requested explicitly, stays on
            this device, and can be revoked in your browser settings at any time.
          </p>
        </div>
      </div>

      <div className="mt-6 grid gap-3 sm:grid-cols-2">
        {capabilities.map((c) => {
          const r = results[c.key];
          return (
            <div key={c.key} className="panel flex flex-col gap-3 p-4">
              <div className="flex items-start gap-3">
                <c.icon className="mt-0.5 size-4 text-primary" />
                <div className="flex-1">
                  <p className="text-sm font-medium">{c.title}</p>
                  <p className="text-xs text-muted-foreground">{c.desc}</p>
                </div>
              </div>
              {r && (
                <p
                  className={`break-words font-mono text-[11px] ${r.ok ? "text-signal" : "text-destructive"}`}
                >
                  {r.text}
                </p>
              )}
              <button
                onClick={c.run}
                className="self-start rounded-lg border border-border px-3 py-1.5 font-mono text-[11px] text-muted-foreground transition-colors hover:border-primary/60 hover:text-primary"
              >
                {r?.ok ? "refresh" : "grant access"}
              </button>
            </div>
          );
        })}
      </div>

      {stream && (
        <div className="panel mt-4 overflow-hidden">
          <video
            autoPlay
            playsInline
            muted
            ref={(el) => {
              if (el && el.srcObject !== stream) el.srcObject = stream;
            }}
            className="h-64 w-full object-cover"
          />
          <button
            onClick={() => {
              stream.getTracks().forEach((t) => t.stop());
              setStream(null);
            }}
            className="w-full border-t border-border py-2 font-mono text-[11px] text-muted-foreground hover:text-destructive"
          >
            stop camera
          </button>
        </div>
      )}
    </div>
  );
}

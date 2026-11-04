#!/usr/bin/env python3
"""Capture deterministic Flutter Web screenshots through the Chrome DevTools Protocol."""
import argparse
import base64
import json
import os
import shutil
import socket
import subprocess
import tempfile
import time
import urllib.request

import websocket

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"


def free_port():
    s = socket.socket()
    s.bind(("127.0.0.1", 0))
    port = s.getsockname()[1]
    s.close()
    return port


class CDP:
    def __init__(self, ws_url):
        self.ws = websocket.create_connection(ws_url, timeout=60)
        self.next_id = 1

    def call(self, method, params=None):
        msg_id = self.next_id
        self.next_id += 1
        self.ws.send(json.dumps({"id": msg_id, "method": method, "params": params or {}}))
        while True:
            data = json.loads(self.ws.recv())
            if data.get("id") == msg_id:
                if "error" in data:
                    raise RuntimeError(data["error"])
                return data.get("result", {})

    def close(self):
        self.ws.close()


def wait_devtools(port, timeout=45):
    start = time.time()
    while time.time() - start < timeout:
        try:
            with urllib.request.urlopen(f"http://127.0.0.1:{port}/json/list", timeout=1) as r:
                data = json.load(r)
            pages = [t for t in data if t.get("type") == "page"]
            if pages:
                return pages[0]["webSocketDebuggerUrl"]
        except Exception:
            time.sleep(0.3)
    raise RuntimeError("Chrome DevTools did not start")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("url")
    parser.add_argument("out")
    parser.add_argument("--width", type=int, default=1440)
    parser.add_argument("--height", type=int, default=900)
    parser.add_argument("--wait", type=float, default=10)
    parser.add_argument("--scale", type=float, default=1)
    parser.add_argument("--scroll", type=int, default=0, help="mouse wheel pixels after load")
    args = parser.parse_args()

    port = free_port()
    profile = tempfile.mkdtemp(prefix="mf-chrome-")
    proc = subprocess.Popen(
        [
            CHROME,
            "--headless=new",
            f"--remote-debugging-port={port}",
            f"--user-data-dir={profile}",
            "--no-sandbox",
            "--remote-allow-origins=*",
            "--hide-scrollbars",
            "--autoplay-policy=no-user-gesture-required",
            "--disable-background-timer-throttling",
            "--disable-backgrounding-occluded-windows",
            "--disable-renderer-backgrounding",
            "--disable-features=CalculateNativeWinOcclusion",
            f"--window-size={args.width},{args.height}",
            "about:blank",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        cdp = CDP(wait_devtools(port))
        cdp.call("Page.enable")
        cdp.call("Emulation.setFocusEmulationEnabled", {"enabled": True})
        cdp.call(
            "Emulation.setDeviceMetricsOverride",
            {
                "width": args.width,
                "height": args.height,
                "deviceScaleFactor": args.scale,
                "mobile": False,
            },
        )
        cdp.call("Page.navigate", {"url": args.url})
        time.sleep(args.wait)
        if args.scroll:
            cdp.call(
                "Input.dispatchMouseEvent",
                {
                    "type": "mouseWheel",
                    "x": args.width // 2,
                    "y": args.height // 2,
                    "deltaX": 0,
                    "deltaY": args.scroll,
                },
            )
            time.sleep(1.5)
        shot = cdp.call("Page.captureScreenshot", {"format": "png", "fromSurface": True})
        with open(args.out, "wb") as f:
            f.write(base64.b64decode(shot["data"]))
        cdp.close()
        print(f"saved {args.out} ({os.path.getsize(args.out)} bytes)")
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()
        shutil.rmtree(profile, ignore_errors=True)


if __name__ == "__main__":
    main()

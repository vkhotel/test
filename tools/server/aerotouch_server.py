#!/usr/bin/env python3
"""
AeroTouch reference desktop receiver.

This is a small, optional reference implementation of the *other end* of the
AeroTouch protocol - it is NOT part of the Flutter app, but lets you test the
whole system end-to-end on Windows, macOS, or Linux without building your own
receiver first.

It does two things:
  1. Answers UDP broadcast discovery requests on port 58008, so the phone's
     "Connect" screen can find this machine automatically.
  2. Runs a WebSocket server on port 58712 that accepts AeroTouch's JSON
     command protocol and drives the real mouse/keyboard via `pyautogui`.

Install:
    pip install -r requirements.txt

Run:
    python aerotouch_server.py
"""
from __future__ import annotations

import asyncio
import json
import socket
import sys
import time
from dataclasses import dataclass

import pyautogui
import websockets
from websockets.server import WebSocketServerProtocol

DISCOVERY_PORT = 58008
WEBSOCKET_PORT = 58712
IS_MAC = sys.platform == "darwin"

# pyautogui adds a small delay after every call by default, which would
# devastate our latency budget at 100Hz - disable it. We also disable the
# fail-safe corner since a fast-moving relative mouse can legitimately pass
# through a screen corner.
pyautogui.PAUSE = 0
pyautogui.FAILSAFE = False


@dataclass
class ServerStats:
    messages_received: int = 0
    started_at: float = time.time()


stats = ServerStats()


def handle_motion(dx: float, dy: float) -> None:
    pyautogui.moveRel(dx, dy, duration=0)


def handle_left_click() -> None:
    pyautogui.click()


def handle_double_click() -> None:
    pyautogui.doubleClick()


def handle_right_click() -> None:
    pyautogui.rightClick()


def handle_left_button_down() -> None:
    pyautogui.mouseDown()


def handle_left_button_up() -> None:
    pyautogui.mouseUp()


def handle_scroll(dx: float, dy: float) -> None:
    # pyautogui's scroll unit is "clicks", not pixels - scale down and invert
    # so swiping up (negative dy from the phone) scrolls the page up.
    if dy:
        pyautogui.scroll(int(-dy))
    if dx:
        pyautogui.hscroll(int(dx))


def handle_back() -> None:
    if IS_MAC:
        pyautogui.hotkey("command", "[")
    else:
        pyautogui.hotkey("alt", "left")


def handle_forward() -> None:
    if IS_MAC:
        pyautogui.hotkey("command", "]")
    else:
        pyautogui.hotkey("alt", "right")


def handle_zoom(delta: float) -> None:
    modifier = "command" if IS_MAC else "ctrl"
    pyautogui.keyDown(modifier)
    try:
        pyautogui.scroll(int(delta * 10))
    finally:
        pyautogui.keyUp(modifier)


async def handle_message(raw: str, websocket: WebSocketServerProtocol) -> None:
    try:
        message = json.loads(raw)
    except json.JSONDecodeError:
        return

    stats.messages_received += 1
    msg_type = message.get("type")

    if msg_type == "motion":
        handle_motion(float(message.get("dx", 0)), float(message.get("dy", 0)))
    elif msg_type == "leftClick":
        handle_left_click()
    elif msg_type == "doubleClick":
        handle_double_click()
    elif msg_type == "rightClick":
        handle_right_click()
    elif msg_type == "leftButtonDown":
        handle_left_button_down()
    elif msg_type == "leftButtonUp":
        handle_left_button_up()
    elif msg_type == "scroll":
        handle_scroll(float(message.get("dx", 0)), float(message.get("dy", 0)))
    elif msg_type == "back":
        handle_back()
    elif msg_type == "forward":
        handle_forward()
    elif msg_type == "zoom":
        handle_zoom(float(message.get("delta", 0)))
    elif msg_type == "ping":
        # Heartbeat: echo the timestamp straight back so the phone can
        # compute round-trip latency.
        await websocket.send(json.dumps({"type": "pong", "ts": message.get("ts")}))


async def connection_handler(websocket: WebSocketServerProtocol) -> None:
    peer = websocket.remote_address
    print(f"[AeroTouch] Phone connected from {peer}")
    try:
        async for raw in websocket:
            await handle_message(raw, websocket)
    except websockets.ConnectionClosed:
        pass
    finally:
        print(f"[AeroTouch] Phone disconnected: {peer}")


class DiscoveryProtocol(asyncio.DatagramProtocol):
    """Answers AeroTouch's UDP broadcast discovery requests."""

    def __init__(self, host_name: str) -> None:
        self._host_name = host_name
        self._transport: asyncio.DatagramTransport | None = None

    def connection_made(self, transport: asyncio.BaseTransport) -> None:
        self._transport = transport  # type: ignore[assignment]

    def datagram_received(self, data: bytes, addr: tuple[str, int]) -> None:
        try:
            message = json.loads(data.decode("utf-8"))
        except (UnicodeDecodeError, json.JSONDecodeError):
            return

        if message.get("type") != "aerotouch_discover":
            return

        response = json.dumps(
            {"type": "aerotouch_announce", "name": self._host_name, "port": WEBSOCKET_PORT}
        ).encode("utf-8")
        if self._transport is not None:
            self._transport.sendto(response, addr)
            print(f"[AeroTouch] Answered discovery request from {addr}")


async def run_discovery_responder() -> None:
    loop = asyncio.get_running_loop()
    host_name = f"{socket.gethostname()}"
    await loop.create_datagram_endpoint(
        lambda: DiscoveryProtocol(host_name),
        local_addr=("0.0.0.0", DISCOVERY_PORT),
        allow_broadcast=True,
    )
    print(f"[AeroTouch] Discovery responder listening on UDP {DISCOVERY_PORT} as '{host_name}'")


async def main() -> None:
    await run_discovery_responder()

    async with websockets.serve(connection_handler, "0.0.0.0", WEBSOCKET_PORT):
        print(f"[AeroTouch] WebSocket server listening on ws://0.0.0.0:{WEBSOCKET_PORT}")
        print("[AeroTouch] Open AeroTouch on your phone, tap Connect, and pick this machine.")
        await asyncio.Future()  # run forever


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[AeroTouch] Shutting down.")

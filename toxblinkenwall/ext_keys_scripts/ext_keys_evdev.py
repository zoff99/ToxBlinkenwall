#! /usr/bin/env python

#*********************************
#
# ToxBlinkenwall - keyboard input script
# (C)strfry in 2019
#
# https://github.com/Zoxcore/ToxBlinkenwall
#
#*********************************

import asyncio

import evdev
from evdev import ecodes

from time import sleep     # this lets us have a time delay (see line 15)

import time
import os
last_button_press = 0
button_press_min_delay_ms = 400 # 400ms until you can register the same button press again

fifo_path = '../ext_keys.fifo'
cur_button = -1

try:
    os.mkfifo(fifo_path)
except Exception:
    pass

fifo_write = open(fifo_path, 'w')

def send_event(txt):
    fifo_write.write(txt)
    fifo_write.flush()

devices = [evdev.InputDevice(path) for path in evdev.list_devices()]

keymap = {
    ecodes.KEY_0: "hangup:\n",
    ecodes.KEY_1: "call:1\n",
    ecodes.KEY_2: "call:2\n",
    ecodes.KEY_3: "call:3\n",
    ecodes.KEY_4: "call:4\n",
    ecodes.KEY_5: "call:5\n",
    ecodes.KEY_6: "call:6\n",
    ecodes.KEY_7: "call:7\n",
    ecodes.KEY_8: "call:8\n",
    ecodes.KEY_9: "call:9\n",
    ecodes.KEY_A: "BT-A:\n",
    ecodes.KEY_B: "BT-B:\n",
    ecodes.KEY_C: "BT-C:\n",
    ecodes.KEY_D: "BT-D:\n",
    ecodes.KEY_S: "toggle_speaker:\n",
    ecodes.KEY_Q: "toggle_quality:\n",
}

keyboards = []
for dev in devices:
    keys = dev.capabilities().get(ecodes.EV_KEY, None)
    if keys:
        keyboards += [dev]

        # Lock Keyboard from terminal
        # dev.grab()

try:
    async def print_events(device):    
        async for event in device.async_read_loop():
            kevent = evdev.util.categorize(event)
            if isinstance(kevent, evdev.KeyEvent):
                code = ecodes.ecodes[kevent.keycode] # map string to keycode object
                if kevent.keystate == 1 and code in keymap: # 1 == keydown
                    send_event(keymap[code])

    for device in keyboards:
        asyncio.ensure_future(print_events(device))

    loop = asyncio.get_event_loop()
    loop.run_forever()

finally:                   # this block will run no matter how the try block exits
    fifo_write.close()

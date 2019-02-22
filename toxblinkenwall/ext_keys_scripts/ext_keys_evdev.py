#! /usr/bin/env python

#*********************************
#
# ToxBlinkenwall - keyboard input script
# (C)strfry in 2019
# (C)Zoff in 2019
#
# https://github.com/Zoxcore/ToxBlinkenwall
#
#*********************************

import asyncio
import evdev
from evdev import ecodes

import time
import os
import signal

fifo_path = '../ext_keys.fifo'
cur_button = -1

try:
    os.mkfifo(fifo_path)
except Exception:
    pass


def send_event(txt):
    #print (txt)
    fifo_write = open(fifo_path, 'w')
    fifo_write.write(txt)
    fifo_write.flush()
    fifo_write.close()

async def print_events(device):    
    last_button_press = 0
    button_press_min_delay_ms = 400 # 400ms until you can register the same button press again
    #print ("print_events:start")
    async for event in device.async_read_loop():
        kevent = evdev.util.categorize(event)
        if isinstance(kevent, evdev.KeyEvent):
            code = ecodes.ecodes[kevent.keycode] # map string to keycode object
            if kevent.keystate == 1 and code in keymap: # 1 == keydown
                if (last_button_press + button_press_min_delay_ms) <  int(round(time.time() * 1000)):
                    last_button_press = int(round(time.time() * 1000))
                    send_event(keymap[code])

devices = [evdev.InputDevice(path) for path in evdev.list_devices()]

keymap = {
    # normal keys
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

    # keypad keys
    ecodes.KEY_KP0: "hangup:\n",
    ecodes.KEY_KP1: "call:1\n",
    ecodes.KEY_KP2: "call:2\n",
    ecodes.KEY_KP3: "call:3\n",
    ecodes.KEY_KP4: "call:4\n",
    ecodes.KEY_KP5: "call:5\n",
    ecodes.KEY_KP6: "call:6\n",
    ecodes.KEY_KP7: "call:7\n",
    ecodes.KEY_KP8: "call:8\n",
    ecodes.KEY_KP9: "call:9\n",
    ecodes.KEY_KPPLUS: "play-vol:up\n",
    ecodes.KEY_KPMINUS: "play-vol:down\n",

    # normal keys
    ecodes.KEY_A: "BT-A:\n",
    ecodes.KEY_B: "BT-B:\n",
    ecodes.KEY_C: "BT-C:\n",
    ecodes.KEY_D: "BT-D:\n",
    ecodes.KEY_L: "play-vol:up\n",
    ecodes.KEY_K: "play-vol:down\n",
    ecodes.KEY_C: "camera-orient:turn-right\n",
    ecodes.KEY_D: "display-orient:turn-right\n",
}

keyboards = []
for dev in devices:
    keys = dev.capabilities().get(ecodes.EV_KEY, None)
    if keys:
        keyboards += [dev]
        # Lock Keyboard from terminal
        # dev.grab()

try:
    for device in keyboards:
        asyncio.ensure_future(print_events(device))

    loop = asyncio.get_event_loop()
    loop.run_forever()

finally:                   # this block will run no matter how the try block exits
    # fifo_write.close()
    pass

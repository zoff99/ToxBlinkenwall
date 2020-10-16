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
import distutils.util

fifo_path = '../ext_keys.fifo'
cur_button = -1

handle_exit_env = os.getenv("TBW_KILLSWITCH_ENGAGE")
handle_debug_env = os.getenv("TBW_EXTKEYS_EVDEV_DEBUG")

def handle_exit():
    if handle_exit_env != None:
        os.system("(cd ../ ; ./start_user_menu.sh )&")
        os.system("../initscript.sh stop &")
        exit()

try:
    os.mkfifo(fifo_path)
except Exception:
    pass


def send_event(txt):
    if handle_debug_env != None:
        print (txt)
        return

    if "XX-dummy-exit-dummy-XX:" in txt:
        handle_exit()

    try:
        fifo_write = os.open(fifo_path, os.O_WRONLY | os.O_NONBLOCK);
        os.write(fifo_write, bytes(txt, 'UTF-8'));
        os.fsync(fifo_write);
        os.close(fifo_write);
    except Exception:
        print("EXCEPTION:001")
        time.sleep(0.3)


async def handle_keys(device):
    last_button_press = 0
    button_press_min_delay_ms = 400 # 400ms until you can register the same button press again

    async for event in device.async_read_loop():
        kevent = evdev.util.categorize(event)
        if isinstance(kevent, evdev.KeyEvent):
            if not isinstance(kevent.keycode, list):
                code = ecodes.ecodes[kevent.keycode] # map string to keycode object
                if kevent.keystate == 1 and code in keymap: # 1 == keydown
                    if (last_button_press + button_press_min_delay_ms) <  int(round(time.time() * 1000)):
                        last_button_press = int(round(time.time() * 1000))
                        send_event(keymap[code])

def is_keyboard(device):
    return True if device.capabilities().get(ecodes.EV_KEY, None) else False

async def scan_for_keyboards():
    keyboards = set()
    tasks = set()
    while True:
        devices = [evdev.InputDevice(path) for path in evdev.list_devices()]
        for device in filter(is_keyboard, devices):
            if device.phys not in keyboards:
                keyboards.add(device.phys)
                print("Detected new key device:", device.phys)
                task = asyncio.ensure_future(handle_keys(device))

                task.add_done_callback(lambda _,phys=device.phys: keyboards.remove(phys))
                tasks.add(task)
        if tasks:
            done, tasks = await asyncio.wait(tasks, timeout=1.0, return_when=asyncio.FIRST_EXCEPTION)
            for task in done:
                if task.exception():
                    print(task, task.exception())
        else:
            await asyncio.sleep(2)

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
    # ecodes.KEY_PLUS: "play-vol:up\n", ## funny enough there is no "+" key defined
    ecodes.KEY_MINUS: "play-vol:down\n",
    ecodes.KEY_VOLUMEUP: "play-vol:up\n",
    ecodes.KEY_VOLUMEDOWN: "play-vol:down\n",

    # normal keys
    ecodes.KEY_A: "BT-A:\n",
    ecodes.KEY_B: "BT-B:\n",
    ecodes.KEY_C: "camera-orient:turn-right\n",
    ecodes.KEY_D: "display-orient:turn-right\n",
    ecodes.KEY_E: "XX-dummy-exit-dummy-XX:\n",
    # F
    ecodes.KEY_G: "BT-C:\n", # C key is taken
    ecodes.KEY_H: "BT-D:\n", # D key is taken
    # I
    # J
    ecodes.KEY_K: "play-vol:down\n",
    ecodes.KEY_L: "play-vol:up\n",
    # M
    # N
    ecodes.KEY_P: "toggle_osd:\n",
    ecodes.KEY_P: "pickup:\n",
    ecodes.KEY_Q: "toggle_quality:\n",
    ecodes.KEY_R: "play-vol:down\n",
    # S
    ecodes.KEY_T: "play-vol:up\n",
    # U
    # V
    # W
    ecodes.KEY_X: "debug-on:\n",
    ecodes.KEY_Y: "debug-off:\n",
}

try:
    task = asyncio.ensure_future(scan_for_keyboards())
    loop = asyncio.get_event_loop()

    def exception_handler(loop, context):
        print("Exception in ", loop, context, "raising")
        sys.exit()

    loop.run_until_complete(task)
finally:
    # this block will run no matter how the try block exits
    pass


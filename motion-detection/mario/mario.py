#!/usr/bin/python
import RPi.GPIO as GPIO
import time
import os
from os import path
import random

SENSOR_PIN = 23
SOUND_DIR = "/usr/share/sounds/mario/"
STOP_FILE = "/tmp/stop_motiondetection"
TIMER_FILE = "/tmp/mario_timer"

GPIO.setmode(GPIO.BCM)
GPIO.setup(SENSOR_PIN, GPIO.IN)

def motion_detected(channel):
    if path.isfile(STOP_FILE):
        print("Stop-File detected, stopping service...")
        GPIO.cleanup()
        os.remove(STOP_FILE)
        exit(0)
    else:
        FILE = random.choice(os.listdir(SOUND_DIR))
        os.system('aplay ' + os.path.join(SOUND_DIR, FILE))
        now = int(time.time())
        f = open(TIMER_FILE, "w")
        f.write('%d' % now);
        f.close()

def check(channel):
    shouldCheck = True
    now = int(time.time())
    if path.isfile(TIMER_FILE):
        f = open(TIMER_FILE, "r")
        ts = int(f.read())
        f.close()
        shouldCheck = (now - ts) >= 1800
    if shouldCheck:
        motion_detected(channel)

try:
    GPIO.add_event_detect(SENSOR_PIN , GPIO.RISING, callback=check)
    while True:
            time.sleep(100)
finally:
    GPIO.cleanup()

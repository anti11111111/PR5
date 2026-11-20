"""Headless screenshots of the salon auth build."""

import os
import shutil
import subprocess

CHROME = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
OUT = os.path.join(os.path.dirname(__file__), "..", "report", "screenshots")
BASE = "http://127.0.0.1:5560"

SHOTS = [
    ("01_login.png", "/login", "1100,820", "12000"),
    ("02_bad_login.png", "/login?preview=bad", "1100,820", "20000"),
    ("03_register.png", "/register?preview=weak", "1100,900", "12000"),
    ("04_reader.png", "/?shot=reader", "1100,900", "20000"),
    ("05_manager.png", "/?shot=manager", "1100,980", "20000"),
    ("06_admin.png", "/?shot=admin", "1100,980", "20000"),
    ("07_my.png", "/my?shot=reader", "1100,820", "20000"),
    ("08_desk.png", "/desk?shot=manager", "1100,820", "20000"),
    ("09_users.png", "/users?shot=admin", "1100,820", "20000"),
    ("10_stats.png", "/stats?shot=admin", "1100,820", "20000"),
    ("11_forbidden.png", "/users?shot=reader", "1100,820", "20000"),
    ("12_idle.png", "/?shot=reader&preview=idle", "1100,900", "20000"),
    ("13_ended.png", "/login?reason=idle", "1100,820", "12000"),
    ("14_tamper.png", "/?shot=reader&tamper=admin", "1100,980", "20000"),
    ("15_denied.png", "/users?shot=reader&tamper=admin", "1100,820", "20000"),
]


def shot(name, path, size, budget):
    target = os.path.abspath(os.path.join(OUT, name))
    profile = os.path.join(os.environ["TEMP"], "salon-pr5-" + name)
    shutil.rmtree(profile, ignore_errors=True)
    print("SHOT", name, flush=True)
    subprocess.run(
        [
            CHROME,
            "--headless=new",
            "--disable-gpu",
            "--hide-scrollbars",
            "--force-device-scale-factor=1",
            f"--window-size={size}",
            f"--user-data-dir={profile}",
            f"--screenshot={target}",
            f"--virtual-time-budget={budget}",
            BASE + path,
        ],
        check=False,
    )
    if os.path.exists(target):
        print(" size", os.path.getsize(target), flush=True)
    else:
        print(" MISSING", flush=True)
    shutil.rmtree(profile, ignore_errors=True)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    for item in SHOTS:
        shot(*item)

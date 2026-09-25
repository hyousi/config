#!/usr/bin/env python3
"""rstat — a TUI for a running rclone job, driven by its --rc interface.

Installed by home-manager as `rstat`; source lives in
modules/home-manager/dotfiles/rstat.py.

The job must have been started with:
    --rc --rc-addr 127.0.0.1:5572 --rc-no-auth

Usage:
    rstat [--addr HOST:PORT] [--interval SECONDS]

Keys:
    q / Esc   quit (the transfer keeps running)
    p         throttle to 1 KiB/s  ·  o  remove the limit
    [ / ]     bandwidth limit down / up by 1 MiB/s
    r         poll now
"""

import argparse
import collections
import curses
import json
import time
import urllib.error
import urllib.request

UNITS = ("B", "KiB", "MiB", "GiB", "TiB", "PiB")
SPARK = " ▁▂▃▄▅▆▇█"


# ── rc client ──────────────────────────────────────────────────────────────


class RC:
    def __init__(self, addr):
        self.base = f"http://{addr}"
        self.error = None

    def call(self, method, **params):
        body = json.dumps(params).encode()
        req = urllib.request.Request(
            f"{self.base}/{method}",
            data=body,
            headers={"Content-Type": "application/json"},
        )
        try:
            with urllib.request.urlopen(req, timeout=3) as r:
                self.error = None
                return json.load(r)
        except urllib.error.HTTPError as e:
            self.error = f"{method}: HTTP {e.code}"
        except (urllib.error.URLError, OSError, json.JSONDecodeError) as e:
            self.error = f"{method}: {e}"
        return None


# ── formatting ─────────────────────────────────────────────────────────────


def human(n, suffix=""):
    n = float(n or 0)
    for unit in UNITS:
        if abs(n) < 1024 or unit == UNITS[-1]:
            return f"{n:,.1f} {unit}{suffix}" if unit != "B" else f"{n:,.0f} B{suffix}"
        n /= 1024


def hms(sec):
    if sec is None:
        return "--:--:--"
    sec = int(sec)
    return f"{sec // 3600:d}:{(sec % 3600) // 60:02d}:{sec % 60:02d}"


def shorten(name, width):
    if width <= 3 or len(name) <= width:
        return name[:width]
    keep = width - 1
    head = keep // 2
    return name[:head] + "…" + name[len(name) - (keep - head):]


# ── drawing ────────────────────────────────────────────────────────────────


class UI:
    def __init__(self, stdscr):
        self.scr = stdscr
        curses.curs_set(0)
        stdscr.nodelay(True)
        self.color = curses.has_colors()
        if self.color:
            curses.use_default_colors()
            for i, fg in enumerate(
                (
                    curses.COLOR_CYAN,
                    curses.COLOR_GREEN,
                    curses.COLOR_YELLOW,
                    curses.COLOR_RED,
                    curses.COLOR_BLUE,
                    curses.COLOR_MAGENTA,
                ),
                start=1,
            ):
                curses.init_pair(i, fg, -1)
        self.CYAN, self.GREEN, self.YELLOW, self.RED, self.BLUE, self.MAGENTA = (
            self.pair(i) for i in range(1, 7)
        )
        self.DIM = curses.A_DIM
        self.BOLD = curses.A_BOLD

    def pair(self, i):
        return curses.color_pair(i) if self.color else 0

    def put(self, y, x, text, attr=0):
        """addstr that never raises on overflow or a too-small terminal."""
        h, w = self.scr.getmaxyx()
        if not (0 <= y < h) or x >= w:
            return
        text = text[: max(0, w - x - 1)]
        try:
            self.scr.addstr(y, x, text, attr)
        except curses.error:
            pass

    def rule(self, y, label="", attr=0):
        h, w = self.scr.getmaxyx()
        if label:
            line = f"─── {label} " + "─" * max(0, w - len(label) - 7)
        else:
            line = "─" * (w - 2)
        self.put(y, 1, line, attr)

    def gauge(self, y, x, width, frac, attr=0):
        frac = 0.0 if frac is None else min(max(frac, 0.0), 1.0)
        cells = width - 2
        filled = int(frac * cells)
        part = frac * cells - filled
        bar = "█" * filled
        if filled < cells and part > 0.125:
            bar += SPARK[min(int(part * 8) + 1, 8)]
        self.put(y, x, "▕", self.DIM)
        self.put(y, x + 1, bar.ljust(cells, "░"), attr)
        self.put(y, x + 1 + cells, "▏", self.DIM)


# ── main loop ──────────────────────────────────────────────────────────────


def frac_color(ui, frac, errors):
    if errors:
        return ui.RED | ui.BOLD
    if frac >= 0.999:
        return ui.GREEN | ui.BOLD
    return ui.CYAN | ui.BOLD


def draw(ui, stats, rc, hist, interval, bwlimit, last_poll):
    scr = ui.scr
    scr.erase()
    h, w = scr.getmaxyx()
    inner = w - 2

    # ── title bar ──
    title = " rclone "
    ui.put(0, 1, "┌" + "─" * (inner - 2) + "┐", ui.DIM)
    ui.put(0, 3, title, ui.MAGENTA | ui.BOLD)
    if stats is None:
        ui.put(2, 3, "waiting for rclone rc …", ui.YELLOW | ui.BOLD)
        ui.put(4, 3, f"endpoint  {rc.base}", ui.DIM)
        ui.put(5, 3, f"error     {rc.error or 'unknown'}", ui.DIM)
        ui.put(7, 3, "The job must run with  --rc --rc-addr 127.0.0.1:5572 --rc-no-auth", ui.DIM)
        ui.put(h - 1, 1, " q quit   r retry ", ui.DIM)
        scr.refresh()
        return

    done = stats.get("bytes", 0)
    total = stats.get("totalBytes", 0) or 0
    frac = (done / total) if total else None
    errors = stats.get("errors", 0)
    speed = stats.get("speed", 0)
    attr = frac_color(ui, frac or 0, errors)

    pct = f"{(frac or 0) * 100:5.1f}%"
    ui.put(1, 3, pct, attr)
    gx = 3 + len(pct) + 1
    gw = max(10, inner - len(pct) - 26)
    ui.gauge(1, gx, gw, frac, attr)
    ui.put(1, gx + gw + 2, f"{human(speed, '/s'):>13}", ui.GREEN | ui.BOLD)

    ui.put(2, 3, f"{human(done)} of {human(total)}", 0)
    right = f"ETA {hms(stats.get('eta'))}   elapsed {hms(stats.get('elapsedTime'))}"
    ui.put(2, max(3, w - len(right) - 3), right, ui.DIM)

    # ── stat row ──
    cells = [
        ("files", f"{stats.get('transfers', 0)}/{stats.get('totalTransfers', 0)}", 0),
        ("checks", f"{stats.get('checks', 0)}/{stats.get('totalChecks', 0)}", 0),
        ("errors", str(errors), ui.RED | ui.BOLD if errors else ui.GREEN),
        ("limit", bwlimit, ui.YELLOW if bwlimit not in ("off", "—") else ui.DIM),
    ]
    x = 3
    for label, value, va in cells:
        ui.put(3, x, label, ui.DIM)
        ui.put(3, x + len(label) + 1, value, va or 0)
        x += len(label) + len(value) + 4

    # ── throughput sparkline ──
    row = 4
    if hist and w > 30:
        peak = max(hist) or 1
        spark = "".join(SPARK[min(int(v / peak * 8) + (1 if v else 0), 8)] for v in hist)
        ui.put(row, 3, spark[-(inner - 20):], ui.BLUE)
        ui.put(row, 3 + len(spark[-(inner - 20):]) + 1, f"peak {human(peak, '/s')}", ui.DIM)
        row += 1

    # ── in-flight transfers ──
    row += 1
    transferring = stats.get("transferring") or []
    ui.rule(row, f"in flight ({len(transferring)})", ui.DIM)
    row += 1
    budget = h - row - 4
    for t in transferring[: max(0, budget)]:
        size = t.get("size", 0) or 0
        tf = (t.get("bytes", 0) / size) if size else None
        # Name starts at column 57; budget it off the real width, not `inner`.
        tname = shorten(t.get("name", "?"), max(8, w - 58))
        ui.put(row, 3, f"{(tf or 0) * 100:5.1f}%", ui.CYAN)
        ui.gauge(row, 10, 22, tf, ui.CYAN)
        ui.put(row, 34, f"{human(t.get('speed', 0), '/s'):>12}", ui.GREEN)
        ui.put(row, 47, f"{hms(t.get('eta')):>8}", ui.DIM)
        ui.put(row, 57, tname, 0)
        row += 1
    if not transferring:
        ui.put(row, 3, "— idle —", ui.DIM)
        row += 1

    # ── last error ──
    if stats.get("lastError"):
        ui.rule(row, "last error", ui.DIM)
        ui.put(row + 1, 3, str(stats["lastError"])[: inner - 4], ui.RED)

    # ── footer ──
    age = time.monotonic() - last_poll
    keys = " q quit   p throttle   o unthrottle   [ ] ±1M   r poll "
    tail = f"{rc.base}  ·  every {interval:g}s  ·  {age:.1f}s ago "
    if len(keys) + len(tail) + 2 > w:
        # Too narrow for both: keys matter more than the endpoint reminder.
        keys = " q  p  o  [ ]  r "
        tail = f"{age:.1f}s ago "
    ui.put(h - 1, 1, keys, ui.DIM)
    if len(keys) + len(tail) + 2 <= w:
        ui.put(h - 1, max(1, w - len(tail) - 1), tail, ui.DIM)
    scr.refresh()


def parse_rate(value):
    """'10M' / '1k' / 'off' → bytes/s or None."""
    value = str(value).strip()
    if value in ("off", "0", ""):
        return None
    mult = {"k": 1024, "M": 1024**2, "G": 1024**3}
    if value[-1] in mult:
        return int(float(value[:-1]) * mult[value[-1]])
    return int(value)


def run(stdscr, args):
    ui = UI(stdscr)
    rc = RC(args.addr)
    hist = collections.deque(maxlen=240)
    stats = None
    bwlimit = "—"
    last_poll = 0.0
    poll_now = True

    while True:
        now = time.monotonic()
        if poll_now or now - last_poll >= args.interval:
            stats = rc.call("core/stats")
            if stats is not None:
                hist.append(stats.get("speed", 0) or 0)
                bw = rc.call("core/bwlimit")
                if bw is not None:
                    bwlimit = bw.get("rate", "off") or "off"
            last_poll = now
            poll_now = False

        draw(ui, stats, rc, list(hist), args.interval, bwlimit, last_poll)

        stdscr.timeout(200)
        try:
            key = stdscr.getch()
        except curses.error:
            key = -1

        if key in (ord("q"), ord("Q"), 27):
            return
        if key in (ord("r"), ord("R")):
            poll_now = True
        elif key == ord("p"):
            rc.call("core/bwlimit", rate="1k")
            poll_now = True
        elif key == ord("o"):
            rc.call("core/bwlimit", rate="off")
            poll_now = True
        elif key in (ord("]"), ord("[")):
            cur = parse_rate(bwlimit) or 0
            step = 1024**2
            new = cur + step if key == ord("]") else max(0, cur - step)
            rc.call("core/bwlimit", rate="off" if new == 0 else f"{new // 1024}k")
            poll_now = True
        elif key == curses.KEY_RESIZE:
            stdscr.clearok(True)


def main():
    p = argparse.ArgumentParser(description="TUI for a running rclone job (--rc).")
    p.add_argument("--addr", default="127.0.0.1:5572", help="rclone rc address")
    p.add_argument("--interval", type=float, default=1.0, help="poll interval, seconds")
    args = p.parse_args()
    try:
        curses.wrapper(run, args)
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()

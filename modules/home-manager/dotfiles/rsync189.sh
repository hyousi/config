# rsync189 — push a local directory to 天翼云盘 (189) through OpenList's WebDAV.
#
# Wraps `rclone copy` with the settings that actually work against the 189
# driver, and turns on the --rc interface so `rstat` can show progress.
#
# Source lives in modules/home-manager/dotfiles/rsync189.sh.

usage() {
  cat <<'USAGE'
rsync189 — copy a local directory to 189 via OpenList WebDAV

usage:
  rsync189 [options] SRC DST

  SRC   local path (a directory, or a single file)
  DST   destination on 189. A bare path is taken as relative to the 189 root,
        so "剧集/Anime/Foo" means "openlist:/189/剧集/Anime/Foo". Pass a
        remote-qualified path ("openlist:/189/...") to override.

options:
  -d, --detach       run in the background (survives closing the terminal)
                     and print the log path instead of streaming progress
  -n, --dry-run      show what would be transferred, change nothing
  -t, --transfers N  parallel file uploads (default 2)
  -a, --addr H:P     rclone rc listen address (default 127.0.0.1:5572)
      --bwlimit R    bandwidth limit, e.g. 5M (default: none)
  -h, --help         this text

notes:
  * Comparison is --size-only: 189 does not round-trip mtimes reliably, and a
    size match is what makes an interrupted run resumable. A half-uploaded
    file has the wrong size, so the next run re-sends it.
  * Progress: run `rstat` in another pane, or tail the log file.
  * .DS_Store is always excluded.
USAGE
}

detach=0
dry_run=0
transfers=2
addr=127.0.0.1:5572
bwlimit=""
addr_explicit=0

while [ $# -gt 0 ]; do
  case "$1" in
    -d | --detach)
      detach=1
      shift
      ;;
    -n | --dry-run)
      dry_run=1
      shift
      ;;
    -t | --transfers)
      transfers="$2"
      shift 2
      ;;
    -a | --addr)
      addr="$2"
      addr_explicit=1
      shift 2
      ;;
    --bwlimit)
      bwlimit="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "rsync189: unknown option $1" >&2
      exit 2
      ;;
    *) break ;;
  esac
done

if [ $# -ne 2 ]; then
  usage >&2
  exit 2
fi

src="$1"
dst="$2"

if [ ! -e "$src" ]; then
  echo "rsync189: source does not exist: $src" >&2
  exit 1
fi

# A bare path is relative to the 189 storage root.
case "$dst" in
  *:*) ;;
  /*) dst="openlist:/189$dst" ;;
  *) dst="openlist:/189/$dst" ;;
esac

args=(
  copy "$src" "$dst"
  --size-only
  --exclude ".DS_Store"
  --transfers "$transfers"
  --checkers 4
  --retries 10
  --low-level-retries 20
  --stats 15s --stats-one-line
  --log-level INFO
)
[ -n "$bwlimit" ] && args+=(--bwlimit "$bwlimit")

if [ "$dry_run" -eq 1 ]; then
  # A preview transfers nothing, so it needs neither the rc port nor a log
  # file — which means it still works while a real run holds the port.
  exec rclone "${args[@]}" --dry-run --progress
fi

# One rc listener per port. Refuse to collide instead of silently starting a
# second job whose progress nothing can see.
if rclone rc --rc-addr "$addr" --rc-no-auth core/version >/dev/null 2>&1; then
  echo "rsync189: something is already serving rclone rc on $addr" >&2
  if [ "$addr_explicit" -eq 0 ]; then
    echo "  another rsync189 is probably running; pass --addr 127.0.0.1:5573" >&2
  fi
  exit 1
fi
args+=(--rc --rc-addr "$addr" --rc-no-auth)

logdir="${XDG_STATE_HOME:-$HOME/.local/state}/rsync189"
mkdir -p "$logdir"
slug=$(basename "$src" | tr -cs 'A-Za-z0-9._-' '_')
log="$logdir/$(date +%Y%m%d-%H%M%S)-${slug}.log"

echo "rsync189: $src"
echo "       -> $dst"
echo "   log:    $log"
echo "   rc:     $addr   (run 'rstat' to watch)"

if [ "$detach" -eq 1 ]; then
  nohup rclone "${args[@]}" --log-file "$log" >/dev/null 2>&1 &
  echo "   pid:    $!   (detached)"
else
  exec rclone "${args[@]}" --log-file "$log" --progress
fi

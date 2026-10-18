#!/bin/sh
set -eu
umask 077

app_dir=${CLOUDPOOL_APP_DIR:-/app}
data_dir=${CLOUDPOOL_DATA_DIR:-/data}
export CLOUDPOOL_APP_DIR="$app_dir"
export CLOUDPOOL_RC_PORT=${CLOUDPOOL_RC_PORT:-5533}
export CLOUDPOOL_SCHEME=${CLOUDPOOL_SCHEME:-https}
export PORT=${PORT:-8080}

waiting() {
    printf '%s\n' "$1" >&2
    exec caddy run --config "$app_dir/waiting.Caddyfile" --adapter caddyfile
}

for server_port in "$PORT" "$CLOUDPOOL_RC_PORT"; do
    case "$server_port" in
        ''|*[!0-9]*) printf '%s\n' 'Invalid server port.' >&2; exit 1 ;;
    esac
    if [ "$server_port" -lt 1 ] || [ "$server_port" -gt 65535 ]; then
        printf '%s\n' 'Invalid server port.' >&2; exit 1
    fi
done

if [ -z "${CLOUDPOOL_USER:-}" ] || [ -z "${CLOUDPOOL_PASSWORD:-}" ] || [ -z "${CLOUDPOOL_CONFIG_B64:-}" ]; then
    waiting 'Add the three CLOUDPOOL settings in Blitz.cloud Environment, then restart.'
fi
case "$CLOUDPOOL_USER" in
    *[!a-zA-Z0-9._-]*|'') waiting 'Use only letters, digits, dots, underscores or hyphens in CLOUDPOOL_USER.' ;;
esac
if [ "${#CLOUDPOOL_PASSWORD}" -lt 16 ]; then
    waiting 'CLOUDPOOL_PASSWORD must have at least 16 characters.'
fi
if [ "$(printf '%s' "$CLOUDPOOL_PASSWORD" | LC_ALL=C tr -cd ' -~')" != "$CLOUDPOOL_PASSWORD" ]; then
    waiting 'Use an ASCII password: Latin letters, digits and symbols, with no line breaks.'
fi

mkdir -p "$data_dir/config" "$data_dir/cache"
chmod 700 "$data_dir/config" "$data_dir/cache"
config_file="$data_dir/config/rclone.conf"
marker_file="$data_dir/config/imported.sha256"
temp_file=$(mktemp "$data_dir/config/import.XXXXXX")

if ! printf '%s' "$CLOUDPOOL_CONFIG_B64" | base64 -d > "$temp_file" 2>/dev/null; then
    rm -f "$temp_file"
    waiting 'CLOUDPOOL_CONFIG_B64 is not valid Base64. Copy it again from PowerShell.'
fi
if ! rclone listremotes --config "$temp_file" --ask-password=false > "$temp_file.remotes" 2>/dev/null; then
    rm -f "$temp_file" "$temp_file.remotes"
    waiting 'The configuration cannot be read. Import an unencrypted rclone.conf containing pool.'
fi
if ! grep -qx 'pool:' "$temp_file.remotes"; then
    rm -f "$temp_file" "$temp_file.remotes"
    waiting 'The imported configuration does not contain a remote named pool.'
fi
rm -f "$temp_file.remotes"

seed_hash=$(sha256sum "$temp_file" | cut -d ' ' -f 1)
saved_hash=''
if [ -f "$marker_file" ]; then
    saved_hash=$(cat "$marker_file")
fi
if [ ! -f "$config_file" ] || [ "$seed_hash" != "$saved_hash" ]; then
    if [ -f "$config_file" ]; then
        cp "$config_file" "$config_file.previous"
    fi
    mv "$temp_file" "$config_file"
    chmod 600 "$config_file"
    printf '%s\n' "$seed_hash" > "$marker_file.tmp"
    mv "$marker_file.tmp" "$marker_file"
else
    # Preserve tokens and remote changes made by rclone since the original import.
    rm -f "$temp_file"
fi
unset CLOUDPOOL_CONFIG_B64

export CLOUDPOOL_PASSWORD_HASH
CLOUDPOOL_PASSWORD_HASH=$(caddy hash-password --plaintext "$CLOUDPOOL_PASSWORD")
export RCLONE_RC_USER="$CLOUDPOOL_USER"
export RCLONE_RC_PASS="$CLOUDPOOL_PASSWORD"
export GOMEMLIMIT=${GOMEMLIMIT:-256MiB}

rclone_pid=''
caddy_pid=''
cleanup() {
    trap - EXIT INT TERM
    if [ -n "$caddy_pid" ]; then kill "$caddy_pid" 2>/dev/null || true; fi
    if [ -n "$rclone_pid" ]; then kill "$rclone_pid" 2>/dev/null || true; fi
    if [ -n "$caddy_pid" ]; then wait "$caddy_pid" 2>/dev/null || true; fi
    if [ -n "$rclone_pid" ]; then wait "$rclone_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT
trap 'exit 0' INT TERM

rclone rcd \
    --config "$config_file" \
    --cache-dir "$data_dir/cache" \
    --rc-addr "127.0.0.1:$CLOUDPOOL_RC_PORT" \
    --rc-serve \
    --buffer-size 4M \
    --transfers 2 \
    --log-level NOTICE &
rclone_pid=$!
caddy run --config "$app_dir/Caddyfile" --adapter caddyfile &
caddy_pid=$!

printf '%s\n' 'CloudPool started. Open the app address supplied by Blitz.cloud.'
while kill -0 "$rclone_pid" 2>/dev/null && kill -0 "$caddy_pid" 2>/dev/null; do
    sleep 1
done
printf '%s\n' 'A server process stopped. Check the preceding log messages.' >&2
exit 1

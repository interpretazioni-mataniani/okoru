# Okoru
起こる — "to happen"

Bash logging library providing colored, leveled, timestamped output. Source it into any shell script to get consistent structured logs — including optional file output with automatic rotation.

## Installation

Install the RPM from the [GitHub releases page](https://github.com/interpretazioni-mataniani/okoru/releases):

```bash
dnf install https://github.com/interpretazioni-mataniani/okoru/releases/download/v<version>/okoru-<version>-1.noarch.rpm
```

Installed path: `/usr/share/okoru/okoru.sh`

In the `everything-but-the-bagle` project, okoru is a dependency of kumonoboru and is installed automatically.

## Usage

Source at the top of your script:

```bash
source /usr/share/okoru/okoru.sh
```

### Log levels

Each function takes one or two arguments: `level "message" ["detail"]`

| Function | Color  | Notes |
|----------|--------|-------|
| `debug`  | blue   | Suppressed unless `VERBOSE=1` |
| `info`   | cyan   | |
| `warn`   | orange | |
| `error`  | red    | Appends to `$errors[]`; returns exit code 1 |
| `ok`     | green  | |

Colors are suppressed automatically when stdout is not a terminal (systemd, cron).

### Enable debug output

```bash
VERBOSE=1 ./myscript.sh
```

### Enable file logging

Call `logging` before your first log statement:

```bash
logging "myscript"           # writes to /var/log/okoru/myscript/myscriptLog
logging "myscript" "run1"    # writes to /var/log/okoru/myscript/run1Log
```

The previous log file is timestamped and gzipped automatically on each new run.
Call `end_logging` at the end of your script to rotate the final log file.

### Checking for errors

```bash
if [[ ${#errors[@]} -gt 0 ]]; then
    echo "Completed with errors: ${errors[*]}"
fi
```

## Example

```bash
source /usr/share/okoru/okoru.sh
logging "myscript"

info "Starting up"
debug "Only visible with VERBOSE=1"
warn "Something looks off"
error "This failed" "detail about why"
ok "Done"
```

See `example-script.sh` for a runnable demo (`bash example-script.sh -v` enables debug output).

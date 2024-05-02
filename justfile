set windows-shell := [ "nu", "-c" ]

_default:
 @just --list

clean:
  crystal clear_cache

[windows]
check *flags:
  ./bin/ameba.exe {{ flags }}

[unix]
check *flags:
  ./bin/ameba {{ flags }}

docs *flags:
  crystal docs {{ flags }}

test *spec_files:
  crystal spec --progress {{ spec_files }}

build *flags:
  shards build --release --no-debug --verbose --progress --time {{ flags }}

run *flags:
  shards run --error-trace --progress {{ flags }}

exec exec_file *flags:
  crystal run --error-trace --progress {{ flags }} {{ exec_file }}

bench bench_file *flags:
  crystal run --release --progress {{ flags }} {{ bench_file }}

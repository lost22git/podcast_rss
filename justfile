set windows-shell := [ "nu", "-c" ]

_default:
 @just --list

clean:
  crystal clear_cache

[windows]
check:
  ./bin/ameba.exe

[unix]
check:
  ./bin/ameba

[windows]
genAmebaFile:
  ./bin/ameba.exe --gen-config

[unix]
genAmebaFile:
  ./bin/ameba --gen-config

test *spec_files:
  crystal spec --progress {{ spec_files }}

build:
  shards build --release --no-debug --verbose --progress --time

run:
  shards run --error-trace --progress 

exec +exec_file:
  crystal run --error-trace --progress {{ exec_file }}

bench +bench_file:
  crystal run --release --progress {{ bench_file }}

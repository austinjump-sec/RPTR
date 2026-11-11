## RPTR

RPTR is a Linux x86-64 assembly program that runs a shell command repeatedly, waiting a configurable number of seconds between runs. Each run's output is written to the terminal, making it easy to compare successive results.

## Requirements

- Linux on x86-64
- NASM
- GNU `ld` (binutils)
- A POSIX-compatible `/bin/sh`

On Debian or Ubuntu, install the build tools with:

```sh
sudo apt update
sudo apt install nasm binutils
```

## Build

From the repository directory, assemble and link the program:

```sh
nasm -f elf64 rptr.asm -o rptr.o
ld -o rptr rptr.o
```

This produces the `rptr` executable in the current directory.

## Usage

```sh
./rptr '<COMMAND>' <SECONDS>
```

- `<COMMAND>` is passed to `/bin/sh -c` and should be quoted as one argument.
- `<SECONDS>` must be a positive whole number. It is the delay after each command finishes and before the next run begins.

For example, to print the current time every five seconds:

```sh
./rptr 'date' 5
```

RPTR appends each run's output to the terminal; it does not clear the screen. Stop it with **Ctrl+C**. Since the command is repeatedly executed by a shell, only use commands you trust.

## How it works

1. RPTR checks that it received a command and a delay, then parses the delay as a positive integer.
2. It installs a handler for `SIGINT` and prints its banner and usage text.
3. In a loop, it forks a child process. The child replaces itself with `/bin/sh -c '<COMMAND>'`.
4. The parent waits for that command to finish, sleeps for the specified number of seconds, and starts the next run.

The delay is between completed runs, so the total time between starts is the command's runtime plus the configured delay.

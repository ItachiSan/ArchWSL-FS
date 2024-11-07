# Run Arch command

This action allow the execution of custom commands inside an ArchLinux
container.

The Docker image is based on `archlinux:latest` and has the following additions:
1. The package `base-devel` is installed
2. The user is the `build` user, with full sudo access

## Inputs

### run

**Required.**

A multiline string representing all commands run in the shell.

See the example below for how to run multiple commands.

## Examples

### Run a normal `make` build

```yaml
- uses: .github/actions/run-arch-command
  with:
    run: |
      make clean
      make
```

## Credits

This action was heavily inspired from:
* https://github.com/addnab/docker-run-action
* https://github.com/g4bri3lDev/arch-make-action

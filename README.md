# getallay - Installer for Allay

Allay can be installed by using the command below:

> [!Warning]
> Because Allay has no stable release yet, the command below will
> not work.

```console
curl https://allay-mc.github.io/getallay/getallay.sh -sSf | sh
```

If your platform is not supported by the installer script or you want to install it manually, you have the
following options:

- **Configure the script**: The script works with environment variables in case your platform got detected
  falsly. Read the script's documentation to find out which environment variables are what they do.
- **Download the appropiate archive**: <https://github.com/phoenixr-codes/playground/releases/>
- **Cargo**: `cargo install allay`

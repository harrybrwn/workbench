This repo holds the configuration for building my dev workbench. It uses the
program I created called [pax](https://github.com/harrybrwn/pax).

# Install

```sh
curl -LsSfO https://github.com/harrybrwn/workbench/releases/latest/download/workbench_amd64.deb
sudo apt install -f ./workbench_amd64.deb
```

## TODO

* Add the [ly](https://github.com/fairyglade/ly) display manager
    * requires zig 0.13.0
* Add [jdupes](https://codeberg.org/jbruchon/jdupes).
* A GUI specific package build
    * Add [usbimager](https://bztsrc.gitlab.io/usbimager/)
    * Add obsidian

### Long Term TODOs

* Needs better package management style features.
* GPG signing and upload to S3

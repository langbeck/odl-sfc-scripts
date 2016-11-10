Usage
-

```bash
export http{,s}_proxy=http://your.corporate.proxy:8088/
curl -L https://raw.githubusercontent.com/langbeck/odl-sfc-scripts/master/sfc-demo/setup.sh | bash -x
```

`setup.sh` will do:
- configure sudo to not ask password
- disable any proxy settings present on `/etc/apt/apt.conf`
- clone this repository at `$HOME/git/odl-sfc-scripts`
- configure proxy for apt, docker (systemd), profile, sudo (`env_keep` proxy environment)
- install docker (from `https://get.docker.com/`)
- clone `sfc` repository at `$HOME/git/sfc`
- hard reset the `sfc` repository to a know "stable" version
- apply the patches from this folder
- create "base directories" (folders expected to be present at vagrant image)
- run `sfc-demo/sfc103/setup_odl.sh`
- TBD

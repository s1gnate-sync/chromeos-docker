# chromeos-docker
Docker for chromeos

## Build
Build is very fast and doesn't require anything apart from running termina vm (the usual "Linux development environment") as it builds inside LXD.

1. replace files in `userdata/` with your own
2. build vm run `# build.sh`
3. copy files from `build` dir to some place else

That's it
## Run
To run simply execute `# run.sh`

To ssh into vm run `ssh chronos@192.168.10.2`

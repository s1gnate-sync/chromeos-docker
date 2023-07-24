# chromeos-docker
Docker for chromeos

## Build
Build is very fast and doesn't require anything apart from running termina vm (the usual "Linux development environment") as it builds inside LXD.

1. replace files in `userdata/` with your own
2. build vm run `# env CID="<CID_OF_RUNNING_TERMINA>" build.sh` 
3. copy files from `build` dir to some place else

Unfortunately after upgrade to m115 cicerone client has dissapeared so for now CID must be massed by hand.

That's it
## Run
To run simply execute `# run.sh`

To ssh into vm run `ssh chronos@192.168.10.2`

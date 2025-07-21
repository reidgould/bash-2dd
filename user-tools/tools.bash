

# Usage:
# > ls -1 $(lastRun)
lastRun() { find "/tmp/$USER/2dd/run" -maxdepth 1 | sort | tail -n 1 ; }
cdLastRun() { cd $(lastRun); }


#todo# pack folder into tar
#todo# unpack folder from tar



#todo# snapshot testing




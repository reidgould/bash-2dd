

# Usage:
# > ls -1 $(lastRun)
lastRun() { find "/tmp/$USER/2dd/run" -maxdepth 1 | sort | tail -n 1 ; }
cdLastRun() { cd $(lastRun); }
#todo# implement a "clean" command to 'rm -r "/tmp/$USER/2dd"'



#todo# pack folder into tar
#todo# unpack folder from tar



#todo# snapshot testing



# runDir[^:"]*files[^"]*
# find src -type f | xargs cat | wc -l

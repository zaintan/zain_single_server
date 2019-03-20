#!/bin/bash

### example
### sh server_agent/start.sh node1 1

## NodeName = node1
## ServerNo = 1

### so we can use getenv in skynet
export NodeName=$1

### check valid for NodeName
if [[ "x$NodeName" == "x"]]
then
    echo "You must set NodeName"
    exit
fi

echo "NodeName = $NodeName"

### so we can distinguish different skynet processes
../skynet/skynet server_single/config.lua $NodeName

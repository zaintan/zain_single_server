#!/bin/bash

### example
### sh server_agent/start.sh 1

## ServerIndex = 1

### so we can use getenv in skynet
export ServerIndex=$1

export StartTime=`date +%Y%m%d_%H%M%S`

### so we can distinguish different skynet processes
../skynet/skynet server_agent/config.lua $ServerIndex

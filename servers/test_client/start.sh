#!/bin/bash

### example
### sh server_login/start.sh 1

## ServerIndex = 1

### so we can use getenv in skynet
export ClientName=$1

#export StartTime=`date +%Y%m%d_%H%M%S`
export StartTime=`date +%Y%m%d_%H`

### so we can distinguish different skynet processes
../skynet/skynet test_client/config.lua $ClientName

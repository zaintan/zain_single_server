#!/bin/bash
#sh server_single/start.sh 1

echo "login server 201 start..."
sh server_login/start.sh 201
echo "login server 201 over"
sleep 3

echo "alloc server 301 start..."
sh server_alloc/start.sh 301
echo "alloc server 301 over"
sleep 3

echo "game server 401 start..."
sh server_game/start.sh 401
echo "game server 401 over"
sleep 3

echo "game server 402 start..."
sh server_game/start.sh 402
echo "game server 402 over"
sleep 3

echo "agent server 101 start..."
sh server_agent/start.sh 101
echo "agent server 101 over"
sleep 3

echo "agent server 102 start..."
sh server_agent/start.sh 102
echo "agent server 102 over"
sleep 3

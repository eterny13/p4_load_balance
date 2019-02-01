#!/bin/bash
sudo ip netns exec h1 ip link del eth0 >/dev/null 2>&1
sudo ip netns exec h2 ip link del eth0 >/dev/null 2>&1
sudo ip netns exec h3 ip link del eth0 >/dev/null 2>&1
sudo ip link del s1-eth1 >/dev/null 2>&1
sudo ip link del s2-eth1 >/dev/null 2>&1
sudo ip link del s3-eth1 >/dev/null 2>&1
sudo ip link del s1-eth2 >/dev/null 2>&1
sudo ip link del s2-eth2 >/dev/null 2>&1
sudo ip link del s1-eth3 >/dev/null 2>&1
sudo ip link del s2-eth3 >/dev/null 2>&1
sudo ip link del s3-eth3 >/dev/null 2>&1
sudo ip netns del h1 >/dev/null 2>&1
sudo ip netns del h2 >/dev/null 2>&1
sudo ip netns del h3 >/dev/null 2>&1
sudo killall simple_switch

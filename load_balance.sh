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

p4c load_balance.p4

sudo ip netns add h1
sudo ip netns add h2
sudo ip netns add h3

sudo ip link add h1-eth0 type veth peer name s1-eth1
sudo ip link add h2-eth0 type veth peer name s2-eth1
sudo ip link add h3-eth0 type veth peer name s3-eth1

sudo ip link add s1-eth2 type veth peer name s2-eth2
sudo ip link add s1-eth3 type veth peer name s3-eth2
sudo ip link add s2-eth3 type veth peer name s3-eth3


sudo ethtool --offload h1-eth0 rx off tx off
sudo ethtool --offload h2-eth0 rx off tx off
sudo ethtool --offload h3-eth0 rx off tx off
sudo ethtool --offload s1-eth1 rx off tx off
sudo ethtool --offload s2-eth1 rx off tx off
sudo ethtool --offload s3-eth1 rx off tx off
sudo ethtool --offload s1-eth2 rx off tx off
sudo ethtool --offload s2-eth2 rx off tx off
sudo ethtool --offload s1-eth3 rx off tx off
sudo ethtool --offload s3-eth2 rx off tx off
sudo ethtool --offload s2-eth3 rx off tx off
sudo ethtool --offload s3-eth3 rx off tx off

sudo ip link set dev h1-eth0 addr 00:00:00:00:01:01
sudo ip link set dev h2-eth0 addr 00:00:00:00:02:02
sudo ip link set dev h3-eth0 addr 00:00:00:00:03:03

sudo ip link set dev s1-eth1 addr 00:00:00:00:01:01 # ?
sudo ip link set dev s2-eth1 addr 00:00:00:00:02:02 # ?
sudo ip link set dev s3-eth1 addr 00:00:00:00:03:03 # ?

sudo ip link set dev s1-eth2 addr 00:00:00:01:02:00
sudo ip link set dev s2-eth2 addr 00:00:00:02:02:00
sudo ip link set dev s1-eth3 addr 00:00:00:01:03:00
sudo ip link set dev s3-eth2 addr 00:00:00:03:02:00 # 03:03?
sudo ip link set dev s2-eth3 addr 00:00:00:02:03:00
sudo ip link set dev s3-eth3 addr 00:00:00:03:03:00

sudo ip link set h1-eth0 netns h1
sudo ip link set h2-eth0 netns h2
sudo ip link set h3-eth0 netns h3

sudo ip netns exec h1 ip link set h1-eth0 name eth0
sudo ip netns exec h2 ip link set h2-eth0 name eth0
sudo ip netns exec h3 ip link set h3-eth0 name eth0

sudo ip netns exec h1 ip link set lo up
sudo ip netns exec h2 ip link set lo up
sudo ip netns exec h3 ip link set lo up

sudo ip netns exec h1 ip link set eth0 up
sudo ip netns exec h2 ip link set eth0 up
sudo ip netns exec h3 ip link set eth0 up

sudo ip link set s1-eth1 up
sudo ip link set s2-eth1 up
sudo ip link set s3-eth1 up
sudo ip link set s1-eth2 up
sudo ip link set s2-eth2 up
sudo ip link set s1-eth3 up
sudo ip link set s3-eth2 up
sudo ip link set s2-eth3 up
sudo ip link set s3-eth3 up

sudo ip netns exec h1 ip addr add 10.0.1.1/24 dev eth0
sudo ip netns exec h2 ip addr add 10.0.2.2/24 dev eth0
sudo ip netns exec h3 ip addr add 10.0.3.3/24 dev eth0

sudo ip netns exec h1 arp -s 10.0.1.254 00:00:00:00:01:01
sudo ip netns exec h2 arp -s 10.0.2.254 00:00:00:00:02:02
sudo ip netns exec h3 arp -s 10.0.3.254 00:00:00:00:03:03

sudo ip netns exec h1 ip route add default via 10.0.1.254
sudo ip netns exec h2 ip route add default via 10.0.2.254
sudo ip netns exec h3 ip route add default via 10.0.3.254

sudo simple_switch load_balance.json -i1@s1-eth1 -i2@s1-eth2 -i3@s1-eth3 --device-id 0 --log-console --thrift-port 9090 &
sudo simple_switch load_balance.json -i1@s2-eth1 -i2@s2-eth2 -i3@s2-eth3 --device-id 1 --log-console --thrift-port 9091 &
sudo simple_switch load_balance.json -i1@s3-eth1 -i2@s3-eth2 -i3@s3-eth3 --device-id 2 --log-console --thrift-port 9092 &

sleep 5


simple_switch_CLI --thrift-port 9090 <<EOF
table_add MyIngress.ecmp_group set_ecmp_select 10.0.0.1/32 => 0 2
table_add MyIngress.ecmp_nhop set_nhop 0 => 00:00:00:00:01:02 10.0.2.2 2
table_add MyIngress.ecmp_nhop set_nhop 1 => 00:00:00:00:01:03 10.0.3.3 3
table_add MyEgress.send_frame rewrite_mac 2 => 00:00:00:01:02:00
table_add MyEgress.send_frame rewrite_mac 3 => 00:00:00:01:03:00
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.1.1/32 => 00:00:00:00:01:01 1
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.2.2/32 => 00:00:00:02:02:00 2
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.3.3/32 => 00:00:00:03:02:00 3
EOF

simple_switch_CLI --thrift-port 9091 <<EOF
table_add MyIngress.ecmp_group set_ecmp_select 10.0.2.2/32 => 0 1
table_add MyIngress.ecmp_nhop set_nhop 0 => 00:00:00:00:02:02 10.0.2.2 1
table_add MyEgress.send_frame rewrite_mac 1 => 00:00:00:02:01:00
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.1.1/32 => 00:00:00:01:02:00 2
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.2.2/32 => 00:00:00:00:02:02 1
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.3.3/32 => 00:00:00:03:03:00 3
EOF

simple_switch_CLI --thrift-port 9092 <<EOF
table_add MyIngress.ecmp_group set_ecmp_select 10.0.3.3/32 => 0 1
table_add MyIngress.ecmp_nhop set_nhop 0 => 00:00:00:00:03:03 10.0.3.3 1
table_add MyEgress.send_frame rewrite_mac 1 => 00:00:00:03:01:00
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.3.3/32 => 00:00:00:00:03:03 1
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.1.1/32 => 00:00:00:01:03:00 2
table_add MyIngress.ipv4_lpm ipv4_forward 10.0.2.2/32 => 00:00:00:02:03:00 3
EOF

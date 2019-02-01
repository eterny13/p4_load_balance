# p4-load-balance
2019/2/1 internship


P4 tutorialのload-balanceをmininet使わずにやってみました

```sh
$　bash load-balance.sh   // ネットワークビルド
$　sudo ip netns exec h2 ./receive.py
$　sudo ip netns exec h3 ./receive.py
$　sudo ip netns exec h1 ./send.py 10.0.0.1 "p4"

終わった後はネットワークを消去
$　bash del.sh
```

h1からh2,h3に直接sendしても届くように改良してある

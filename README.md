# ChaosAttractor's Router Configuration

## TODO
- 现在resolved是路由的默认DNS, 并使用 dnsmasq 作为上游, 但好像并没有转发请求给 dnsmasq, 看起来会并发请求networkd提供的上游和dnsmasq，按需采用
- sing-box & tproxy?
- nf_conntrack_acct
- OpenGFW
- 只有源地址是私网地址且目标地址是公网地址的情况下需要NAT，但目前这样根据源接口通过networkd设置NAT似乎也没什么大问题
- 仅三层与内网互通的VLAN? (管理面?)
- 安全（生产）域划分（三层不完全互通?）
- 未来可能直接使用 DoH/DoQ, DAE 不做劫持行为(但监听请求以保证嗅探工作) , DoH/DoQ 的请求由代理节点发出, 并由 fallback 机制保证 DAE 故障时可用

  systemd-resolved目前故障时可用, 或许也可以作为一个fallback的选择, 并且dnsmasq自身就具有fallback机制, 也未必需要起一个 mosdns, 使用一个反代似乎也足以

  但是这样在不故障时会打环

## 地址
### IPv4
#### 地址
WAN 通过 PPP(IPCP)/DHCP 获得地址
#### 路由
进行 NAT

WAN 口获得到的 IP, 上游可以正确路由, 通过 masquerade, 所有连接都从路由本机发出(转发)

### IPv6
#### 地址
WAN 接口通过 DHCP-PD 获取前缀, LAN 接口通过前缀获得地址, 同时通过 SLAAC 获得一个地址, 不使用 DHCP

#### 路由
##### 下行
DHCP-PD 可以使上游将整个段都路由到我的路由器
##### 上行
对于 PPP, 不依赖 default route, 直接 NDP 就能连接, 上游直接是二层网络

对于 DHCP，需要 default route, 因为 WAN 和上游的 PPP 不是二层桥接, 上游还需要进行三层转发

不过, SLAAC 可以自动添加 default route

此外，最好不要关闭AcceptRA, 不接收RA容易导致地址更新不及时（存疑）

## DNS
使用 dnsmasq 作为本地 DNS 服务器, 通过 DHCP 和 SLAAC 提供给 LAN 设备

systemd-resolved 会和 systemd-networkd 联动, 从而获得接口的上游DNS (通常来说是运营商 DNS)

然后他会和 dnsmasq 联动, 提供上游 DNS 信息提供给 dnsmasq, 详见`services.dnsmasq.resolveLocalQueries`:
 - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/system/boot/resolved.nix
 - https://github.com/NixOS/nixpkgs/blob/nixos-unstable/nixos/modules/services/networking/dnsmasq.nix

此外 dnsmasq 还被手动添加了 alidns 并优先使用, 因为运营商 DNS 可能包含更多的 DNS 污染, 并且同时更慢或无显著速度差别
 
systemd-resolved 将作为路由器的默认 DNS, 并默认转发 DNS 请求到 dnsmasq, 亦会在 dnsmasq 故障时使用接口的上游 DNS 进行解析

因此 systemd-resolved 设计上在 dae 故障时可用

具体信息可以通过 `resolvectl status` 查看

### 广告屏蔽 (WIP)
dnsmasq 对广告域名会返回 nxdomain

### DAE
DAE 会劫持所有来自 dnsmasq 的 DNS 请求 (向上游查询的请求), 其他请求则只分流, 不劫持

劫持后直连所有中国网站的域名, 其余一律从默认节点发到 GoogleDNS, 使用默认节点是必要的, 这保证地域路由/CDN工作

并会返回 TTL为0的结果, DAE 进行缓存, 这用于保证嗅探工作

TODO: https://github.com/daeuniverse/dae/issues/474

### DNS 服务器地址
- 127.0.0.1/192.168.8.1: dnsmasq
- 127.0.0.53: systemd-resolved

### DHCP/DNS 权威解析 (TODO)

## VLAN/SDN
默认不处理Untagged流量

| VID                                       | ZONE             | IP/CIDR        | Wireless      | Introduction |
| ----------------------------------------- | ---------------- | -------------- | ------------- | ------------ |
| 1    in downstream                        | lan    -> br-lan | 10.0.0.1/16    | MisakaNetwork | 本地网络 |
| 2    in downstream                        | direct -> br-lan | 10.0.0.1/16    | MikotoNetwork | 本地网络, 不进行透明代理 |
| 10   in downstream                        | security         | 10.1.0.1/16    | NO SSID       | 生成环境, 此VLAN的所有入站都需要单独审计 |
| 100  in downstream                        | manage           | 10.255.0.1/16  | NO SSID       | 管理网络, 限制待定 |
| 1000 in ap                                | ap               | 169.254.2.1/24 | ManageNetwork | AP的管理VLAN, AP自行提供DHCP服务, 用于保证AP可管理, 交换机/路由侧不处理(DROP) |
| 4094 in downstream / untagged in upstream | onu              | 192.168.1.1/24 | ONUNetwork    | 光猫上联 |
| wireguard                                 | vpn              | 10.100.0.1/24  | NO SSID       | VPN / 可信隧道 |

## 防火墙 (TODO)

### Filter
网关的安全性很重要, 所以仅允许的必要的端口可被访问
| Type                                        | Action  |
| ------------------------------------------- | ------- |
| ICMP                           ->  Router   | Allowed |
| DHCPv6 message    from world   ->  Router   | Allowed |
| DHCP message      from private ->  Router   | Allowed |
| SSH/DNS/Wireguard              ->  Router   | Allowed |
| LAN/VPN                        ->  Router   | Allowed |

---

所有网络均可访问外网

LAN/VPN拥有同等安全性, 并且允许所有IPv6连入和ICMP

MANAGE仅可由LAN/VPN连入

SECURITY则需要审计

| Type                                        | Action  |
| ------------------------------------------- | ------- |
| ANY                            ->  World    | Allowed |
| LAN                            <-> VPN      | Allowed |
| LAN/VPN                        ->  MANAGE   | Allowed (网络内设备自行保证安全) |
| ICMO-ECHO-REQUEST from world   ->  LAN/VPN  | Allowed (Weak Security Zone) |
| Any IPv6          from world   ->  LAN/VPN  | Allowed (Weak Security Zone) |
| ANY                            ->  SECURITY | 需要审计 (Strong Security Zone) |

### MSS Clamp
目前会把所有经过 forward 链的流量的 MTU 都设置成 pMTU

## SDN/VPN (Wireguard/TODO)

## 硬件转发 (TODO)
- Flowtable Offload
- OVS Offload

## 5G CPE 热备（TODO）

## CANet 的拓扑 (TODO)

## DAE (TODO)
默认使用日本作为代理出口

DAE根据GEOIP的地区进行分流, 为了保证流量被分流到默认代理出口, 应当保证DNS查询从默认出口发出

对于从默认出口进行DNS查询也返回非日本IP的情况，则使用对应地区的节点发出

随着 https://github.com/daeuniverse/dae/issues/47 的解决, 目前DAE已经有了连接追踪, 虽然可能还未经过充分测试, 但如果按预期工作, UDP连入应该可以正常工作

## 额外功能
### DDNS
### UPNP

## Proxmox Image
To generate proxmox image:
```sh
nix run github:nix-community/nixos-generators -- -c proxmox.nix -f proxmox
```
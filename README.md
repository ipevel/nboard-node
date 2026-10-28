# nboard-node

节点端：加入 nboard 面板，按面板下发的配置驱动代理内核，回传流量与在线会话，并保持证书、限速、设备数在本地与面板一致。

## 形态

单二进制，静态编译，除配置文件外无运行时依赖。控制面只与 nboard 面板通信，业务配置（用户、限速、设备数、路由、证书）全部来自面板。

- 内核：`sing-box` 与 `xray-core` 双内核，默认 `singbox`，可用 `--kernel` 或 `kernel.type` 指定
- 协议：V2Ray 系列、Trojan、Shadowsocks、Hysteria2、TUIC、AnyTLS
- 同步：WebSocket 推送与 REST 轮询双通道
- 部署形态：node（单节点）、machine（面板按机器下发全部节点）、standalone（不接面板的本地模式）
- 多实例：单进程通过 `instances` 同时绑定多个面板或节点

## 配置

配置文件由 `-c` 指定，默认 `config.yml`；安装脚本写入 `/etc/nboard-node/config.yml`。字段说明见 `config.yml.example`。

容器场景可只用环境变量，无需配置文件：

| 变量 | 说明 |
|---|---|
| `apiHost` / `API_HOST` | 面板地址 |
| `apiKey` / `API_KEY` | 面板签发的节点凭证 |
| `nodeID` / `NODE_ID` | 节点 ID |
| `nodeType` / `NODE_TYPE` | 节点类型，可选 |
| `kernel` / `KERNEL_TYPE` | 内核类型，`singbox` 或 `xray` |
| `domain` / `DOMAIN` | TLS 域名，设置后启用自动签发 |
| `certFile` / `CERT_FILE` | 证书路径 |
| `keyFile` / `KEY_FILE` | 私钥路径 |
| `logLevel` / `LOG_LEVEL` | 日志级别 |

配置项 `health_port`（安装脚本对应参数 `--health-port`，安装默认 65530，配置默认关闭）开启本地健康探针，`GET /healthz` 返回 `{"status":"ok"}`，仅代表进程存活。

## 安装

Linux systemd：

```bash
# node 模式
curl -fsSL https://raw.githubusercontent.com/ipevel/nboard-node/dev/install.sh | \
  sudo bash -s -- --mode node --panel https://panel.example.com --token TOKEN --node-id 1

# machine 模式
curl -fsSL https://raw.githubusercontent.com/ipevel/nboard-node/dev/install.sh | \
  sudo bash -s -- --mode machine --panel https://panel.example.com --token TOKEN --machine-id 1
```

安装结果：二进制 `/usr/local/bin/nboard-node`、命令行工具 `/usr/local/bin/nbctl`、状态目录 `/etc/nboard-node`、服务 `nboard-node.service`。脚本可重复执行，用于对齐或修复现有安装。

Docker：

```bash
docker run -d --restart=always --network=host \
  -e apiHost=https://panel.example.com -e apiKey=TOKEN -e nodeID=1 \
  ghcr.io/ipevel/nboard-node:latest
```

## 使用

```bash
nboard-node -c /etc/nboard-node/config.yml   # 前台运行
nboard-node -v                               # 版本
```

`nbctl` 管理实例与服务：

```bash
nbctl status                                        # 服务状态、健康、实例列表
nbctl list [--output text|json]                     # 全部实例
nbctl instance get <id>                             # 单个实例详情
nbctl bind add-node --panel-url URL --token TOKEN --node-id 1
nbctl bind add-machine --panel-url URL --token TOKEN --machine-id 1
nbctl bind remove <instance-id>
nbctl config init --mode node --panel-url URL --token TOKEN --node-id 1
nbctl service restart|logs
nbctl upgrade [--version VERSION]
nbctl uninstall [--purge] [--yes]
```

## 扩展文档

- 自定义路由：[docs-custom-routes.md](docs-custom-routes.md)
- 自定义出站：[docs-custom-outbounds.md](docs-custom-outbounds.md)
- DNS 服务商：[docs-dns-providers.md](docs-dns-providers.md)

## License

MPL-2.0. See [LICENSE](LICENSE).

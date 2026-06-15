# V2 Xray 多功能限制用户一键安装脚本

> 广告位：**KVMCC.COM 互联｜8年全球服务经验｜香港·美国·日本多地区服务区｜安全、可靠、稳定的云服务商**
>
> 本项目为非官方学习/测试脚本，仅用于学习、实验室测试、系统运维练习和合法网络配置研究。使用前请确认当地法律法规、云服务商条款、网络管理要求和使用场景是否合法合规。

## 重要声明

本项目不是 Xray、XTLS、GitHub、任何云厂商或任何第三方的官方项目，也不代表任何第三方立场。脚本中出现的 **KVMCC.COM / www.kvmcc.com** 仅作为广告位/赞助展示，不代表广告主控制、审核、维护、担保、背书或提供本脚本的技术支持。

使用、复制、修改、转载或运行本项目，即表示你已经阅读并同意脚本内的使用须知。使用者必须自行承担合规责任和使用后果。严禁用于未授权访问、攻击、欺诈、垃圾流量、恶意软件、盗号、扫描第三方系统、违反服务条款或任何违法用途。

本脚本按“现状”提供，不承诺可用性、稳定性、适配性或任何结果。作者、贡献者、发布者、转载者、广告主/赞助方及任何被提及名称/域名均不对误用、故障、封禁、损失或法律后果负责。

## 介绍

V2 Xray 多功能限制用户一键安装脚本，面向 Ubuntu 22.04+ 服务器，提供菜单式安装、配置、在线人数限制、日志排查、网络优化和客户端链接导出等功能。

脚本默认部署：

- Xray-core
- VLESS
- TCP
- REALITY
- Vision
- 默认端口 443
- 默认 SNI：`www.microsoft.com`
- 默认在线限制模式：`deny_new`，满员后拒绝新 IP，更稳定

## 主要功能

- 一键安装 / 重装 Xray-core
- 默认保留旧 UUID、REALITY 密钥和 Short ID，避免误重装导致旧链接失效
- 支持强制重置 UUID、REALITY 密钥和 Short ID
- 支持 VLESS + TCP + REALITY + Vision
- 支持自动生成客户端导入链接
- 支持生成 Xray 客户端 JSON 配置
- 支持生成 Mihomo / Clash Meta YAML 配置
- 支持二维码显示，未安装二维码组件时自动跳过
- 支持多源下载 Xray，降低 GitHub 504 或网络失败影响
- 支持指定 Xray 版本安装
- 支持 UFW 防火墙自动放行 SSH 和节点端口
- 支持检测云厂商安全组放行提醒
- 支持端口占用检测，避免 443 被 Nginx、Apache、Caddy、面板等占用导致启动失败
- 支持 BBR、fq、TFO、MTU probing、连接队列、文件句柄优化
- 支持 Fail2ban SSH 防爆破，可选安装，失败不影响主功能
- 支持在线客户端公网 IP 统计
- 支持限制在线客户端公网 IP 数量
- 支持满员后拒绝新客户端 `deny_new`
- 支持满员后踢掉最早旧客户端 `kick_old`
- 支持断线空闲自动释放在线名额
- 支持查看当前在线 IP、已占用名额、当前限制冷却 IP、最近限制日志
- 支持修改在线人数限制与踢下线模式
- 支持修改端口、SNI、DEST、节点名、QUIC 策略
- 支持重启 Xray 与在线限制服务
- 支持查看日志
- 支持生成排查日志包，方便定位故障
- 支持卸载 Xray 和在线限制服务

## 在线人数限制说明

本脚本的“在线人数”按 **客户端公网 IP** 统计，不是按设备数量统计。

示例：

- 同一个家庭 Wi-Fi 下 4 台设备，如果出口公网 IP 相同，只算 1 个名额。
- 4 台设备分别使用 4 个不同公网 IP，才算 4 个名额。
- 服务器本机 IP、回环地址、内网地址不会占用客户端名额。

默认配置：

```bash
MAX_ONLINE_IPS=2
LIMIT_MODE=deny_new
ONLINE_IDLE_SECONDS=300
```

含义：

- 最多允许 2 个客户端公网 IP 同时占用名额。
- 满员后拒绝新 IP，不踢已在线 IP，更稳定。
- 客户端断开后，不会立即释放名额；默认 300 秒无活动后释放，避免手机网络抖动导致名额频繁跳动。

### deny_new 与 kick_old 区别

`deny_new`：推荐长期使用。

```text
前 2 个客户端公网 IP 正常使用。
第 3 个、第 4 个客户端公网 IP 会被拒绝。
已在线客户端不会被踢掉。
```

`kick_old`：适合临时让新设备顶掉旧设备，不推荐多人长期自动重连。

```text
第 3 个客户端进来时，会踢掉最早在线的客户端。
如果多台设备都自动重连，可能出现轮换掉线。
```

## 系统要求

推荐：

- Ubuntu 22.04+
- root 权限
- systemd
- IPv4 公网服务器
- 云厂商安全组放行 SSH 端口和节点端口，默认 TCP 443

脚本会尽量只安装缺失依赖，不执行系统升级。新系统软件源索引为空时，可能会执行一次 `apt-get update` 刷新索引；这不是系统升级。

完全禁止刷新软件源索引：

```bash
sudo APT_REFRESH=0 bash v2_xray_multi_user_limit_installer.sh install
```

## 安装

建议先下载、阅读，再运行。

```bash
wget https://raw.githubusercontent.com/你的用户名/你的仓库名/main/v2_xray_multi_user_limit_installer.sh
chmod +x v2_xray_multi_user_limit_installer.sh
sudo bash v2_xray_multi_user_limit_installer.sh
```

直接安装：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh install
```

自动化安装时，如果已经阅读并同意使用须知：

```bash
sudo ACCEPT_TERMS=1 bash v2_xray_multi_user_limit_installer.sh install
```

## 常用命令

进入菜单：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh
```

一键安装 / 重装：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh install
```

查看运行状态：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh status
```

查看节点链接：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh info
```

查看在线客户端：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh online
```

修改在线人数限制：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh limit
```

生成排查日志包：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh diag
```

卸载：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh uninstall
```

## 指定版本安装

如果 GitHub latest API 不稳定，可以指定 Xray 版本：

```bash
sudo XRAY_VERSION=26.3.27 bash v2_xray_multi_user_limit_installer.sh install
```

## 强制重置节点链接

默认重装会保留旧 UUID、REALITY 密钥和 Short ID，避免旧客户端全部失效。

如果需要强制生成全新链接：

```bash
sudo FORCE_RENEW=1 bash v2_xray_multi_user_limit_installer.sh install
```

也可以使用菜单：

```text
10) 重置 UUID + REALITY 密钥 + Short ID
```

## 菜单说明

```text
1) 环境检测 / 运行状态
2) 一键安装 / 重装
3) 卸载
4) 查看节点链接 / 二维码 / 客户端配置路径
5) 查看客户端在线情况
6) 修改在线人数限制与踢下线模式
7) 修改端口 / SNI / 节点名 / QUIC策略
8) 网络优化菜单
9) 更新 Xray-core
10) 重置 UUID + REALITY 密钥 + Short ID
11) 重启 Xray 与在线限制服务
12) 查看日志
13) 降低封锁与暴露风险建议
14) 生成排查日志包 / 导出故障日记
0) 退出
```

## 故障排查

如果安装失败或连接异常，先生成排查日志包：

```bash
sudo bash v2_xray_multi_user_limit_installer.sh diag
```

生成位置类似：

```text
/root/xray-reality-diagnostics/xray-diagnostic-时间.tar.gz
```

排查时重点看：

- 443 是否被其他程序占用
- Xray 服务是否运行
- Xray 配置是否测试通过
- UFW 是否放行节点端口
- 云厂商安全组是否放行 TCP 443
- 客户端是否支持 VLESS + REALITY + Vision
- 客户端时间是否准确
- SNI / DEST 是否被改错

## 免责声明

本项目仅供学习、测试、实验室环境、系统运维练习和合法网络配置研究使用。不同国家和地区的法律法规、云服务商条款、网络管理要求不同，请使用者自行确认是否允许使用。

禁止将本项目用于未授权访问、攻击、欺诈、垃圾流量、恶意软件、盗号、扫描第三方系统、违反服务条款或任何违法用途。

广告位：**KVMCC.COM 互联｜8年全球服务经验｜香港·美国·日本多地区服务区｜安全、可靠、稳定的云服务商**。广告展示不代表广告主控制、审核、维护、担保、背书或提供本脚本技术支持。


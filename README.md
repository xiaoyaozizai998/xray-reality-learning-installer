# Xray VLESS REALITY Learning Installer

> Unofficial script for learning, lab testing, system administration practice, and lawful network configuration research only.
>
> Sponsor/ad display: **www.kvmcc.com**

## Notice

This project is not affiliated with, endorsed by, or maintained by Xray, XTLS, GitHub, or any cloud provider. The domain **www.kvmcc.com** may be shown as a sponsor/ad display only. This does not mean the advertiser controls, audits, maintains, endorses, guarantees, or provides support for this script. By using, copying, modifying, or redistributing this script, you confirm that you have read and agreed to the notice inside the script.

You are solely responsible for complying with applicable laws, regulations, cloud-provider terms, and network-owner requirements. Do not use this project for unauthorized access, abuse, spam, malware, fraud, credential theft, scanning third-party systems, or any activity that violates applicable law or terms of service.

The script is provided "AS IS", without warranty of any kind. The author(s), contributor(s), publisher(s), redistributor(s), advertiser(s), sponsor(s), and any mentioned names/domains are not responsible for misuse, service interruption, account suspension, data loss, IP blocking, legal consequences, or any direct/indirect loss.

## 中文说明

本项目为非官方学习/测试脚本，仅用于学习、实验室测试、系统运维练习和合法网络配置研究。使用者必须自行确认当地法律法规、云服务商条款、网络管理要求和使用场景是否合法合规。

广告/赞助展示：**www.kvmcc.com**。该展示不代表广告主控制、审核、维护、担保、背书或提供本脚本的技术支持。作者、贡献者、发布者、转载者、广告主/赞助方及任何被提及名称/域名均不对误用、故障、封禁、损失或法律后果负责。

不同意脚本内使用条款，请不要运行、复制、修改或转载本项目。

## Features

- Ubuntu 22.04+ oriented menu installer
- Xray VLESS + TCP + REALITY + Vision configuration
- Multi-source Xray download fallback
- Optional UFW, Fail2ban, BBR/network tuning
- Online client IP limit with `deny_new` or `kick_old`
- Diagnostic log package export

## Usage

Download and review the script first:

```bash
chmod +x xray_vless_reality_public.sh
sudo bash xray_vless_reality_public.sh
```

Install directly:

```bash
sudo bash xray_vless_reality_public.sh install
```

Generate diagnostics:

```bash
sudo bash xray_vless_reality_public.sh diag
```

Automation only after reading and accepting the notice:

```bash
sudo ACCEPT_TERMS=1 bash xray_vless_reality_public.sh install
```

## Important

- Cloud-provider security groups must also allow the selected TCP port, usually 443.
- Client software must support VLESS + REALITY + Vision.
- `deny_new` is recommended for stable online-limit behavior.
- `kick_old` may cause repeated reconnects if many client IPs compete for limited slots.
- Menu option `rotate` resets UUID and REALITY keys; old client links become invalid.

## License

MIT License. See `LICENSE`.

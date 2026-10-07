# caddy-manager

`v2ray-manager` 项目体系中的 Caddy 功能分支项目。它接受主干统一控制，也可以独立安装、验证、
运行、修复和卸载。这里的“分支项目”是架构职责，并非 Git branch。

## 独立安装、验证和卸载

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/0157Martin/caddy-manager/main/install.sh) install
bash <(curl -fsSL https://raw.githubusercontent.com/0157Martin/caddy-manager/main/install.sh) verify
bash <(curl -fsSL https://raw.githubusercontent.com/0157Martin/caddy-manager/main/install.sh) uninstall
```

卸载默认保留 `/etc/caddy`、证书和网站文件，避免误删用户数据。

## 独立命令

```bash
caddy-manager install
caddy-manager verify
caddy-manager static example.com
caddy-manager reverse app.example.com 127.0.0.1:8080
caddy-manager xray cdn.example.com 127.0.0.1:24443 /xhttp
caddy-manager page example.com portfolio
caddy-manager status
caddy-manager log
caddy-manager repair
caddy-manager uninstall
caddy-manager version
```

## 与主干的契约

主干负责下载、许可证与语法校验、命令调用、Xray 入站关联和失败时的项目事务回滚。此分支负责：

- 从官方软件源安装 Caddy；
- 管理 `/etc/caddy/Caddyfile` 和 `/etc/caddy/conf.d/*.caddy`；
- 创建静态站点、本机反向代理以及 Xray XHTTP/WS 路由；
- 部署通用占位页或受校验的可选页面；
- 校验配置并管理 `caddy.service`；
- 检查 TCP 80/443 冲突及 Certbot standalone 续期冲突。

Xray 节点目录可通过 `V2M_NODES_DIR` 指定，默认 `/etc/xray/nodes`。分支只读取这些状态以合并同一
域名的 XHTTP/WS 路径，不修改 Xray 配置或用户凭据。

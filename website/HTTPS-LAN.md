# Just Paste 局域网 HTTPS

在项目根目录运行：

```sh
./website/start-https.sh
```

想让本机浏览器完全信任证书时，先执行一次 `mkcert -install`（会弹出系统授权），再启动脚本。

本机地址：`https://justpaste.localhost:4443`。`.localhost` 是浏览器保留域名，不需要修改 `/etc/hosts`。

同一 Wi-Fi 下的其他设备可访问：`https://<这台 Mac 的局域网 IP>:4443`。首次访问会要求信任 mkcert 根证书；根证书路径可用 `mkcert -CAROOT` 查看。脚本不会把证书或私钥写进 Git，因为它们位于 `website/.certs/`。

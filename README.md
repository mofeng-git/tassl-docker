# TASSL Docker 项目

本项目提供了一个 Docker 镜像，其中包含配置了 TASSL (基于 OpenSSL 1.1.1s) 以支持国密 (GM) SSL 协议的 Nginx。这使得您可以轻松地部署支持国密标准的 Web 服务器或反向代理。

## 背景

国密 SSL 协议（TLCP）在中国用于保障网络通信安全。本项目利用了 [TASSL](https://github.com/jntass/TASSL-1.1.1) 库和定制化的 [Nginx](https://github.com/jntass/Nginx_Tassl) 来提供国密支持。

## 特性

*   **简易部署**: 通过 Docker 简化了环境配置和部署流程，开箱即用，便于快速验证技术可行性。

*   **多平台**: 预镜像构建支持 linux/amd64、linux/arm64、linux/arm/v7 平台。
## 快速开始

```bash
docker run -d -p 80:80 -p 443:443 --name tassl-nginx silentwind0/tassl-nginx
```

## 构建镜像

在项目根目录下运行以下命令来构建 Docker 镜像：

```bash
docker build -t tassl-nginx .
```

使用以下命令运行容器：

```bash
docker run -d -p 80:80 -p 443:443 --name my-tassl-nginx tassl-nginx
```

这将在后台启动一个容器，并将主机的 80 和 443 端口映射到容器的相应端口。

## 配置

### Nginx 配置 (`nginx.conf`)

项目中的 `nginx.conf` 文件已经配置为支持国密 SSL。关键配置项位于 `server` 块中：

```nginx
server {
    listen       443 ssl;
    server_name  localhost; # 或者您的域名
    # 指定国密 TLS 协议版本，注意 TASSL 可能支持不同的协议字符串
    # ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3; # 根据 TASSL 文档调整

    # 国密证书配置
    # ssl_verify_client off; # 根据需要配置客户端证书验证

    ssl_certificate         /usr/local/tassl_demo/cert/certs/SS.crt;  # 签名证书
    ssl_certificate_key     /usr/local/tassl_demo/cert/certs/SS.key;  # 签名私钥
    ssl_enc_certificate     /usr/local/tassl_demo/cert/certs/SE.crt;  # 加密证书
    ssl_enc_certificate_key /usr/local/tassl_demo/cert/certs/SE.key;  # 加密私钥

    # 其他 SSL/TLS 配置...

    location / {
        root   html;
        index  index.html index.htm;
    }
}
```

**重要提示**:

1.  **证书用途**: 签名证书 (`ssl_certificate`) 必须具有数据签名功能，加密证书 (`ssl_enc_certificate`) 必须具有数据加密功能。Dockerfile 中使用 `tassl_demo/cert` 脚本生成的证书已满足这些要求，可用于测试。
2.  **证书路径**: 配置文件中指定的证书路径是容器内的路径。`Dockerfile` 已经将生成的测试证书复制到了 `/usr/local/tassl_demo/cert/certs/`。如果您使用自己的证书，请确保将它们复制到镜像中或通过卷挂载到容器内，并更新 `nginx.conf` 中的路径。
3.  **SSL 协议**: `ssl_protocols` 指令可能需要根据 TASSL 支持的具体协议版本进行调整。请参考 TASSL 的官方文档。

## 测试

要测试国密 SSL 连接，您需要使用支持国密协议的浏览器：

*   **奇安信可信浏览器国密开发者专版**: [下载地址](https://www.qianxin.com/ctp/gmbrowser.html)

*   **360 安全浏览器 (国密专版)**: [下载地址](https://browser.360.cn/se/ver/gmzb.html)


使用这些浏览器访问 `https://<your-server-ip-or-domain>` (如果使用了默认证书，访问 `https://localhost` 或容器 IP)。

## 参考

*   **TASSL**: [https://github.com/jntass/TASSL-1.1.1](https://github.com/jntass/TASSL-1.1.1)
*   **Nginx_Tassl**: [https://github.com/jntass/Nginx_Tassl](https://github.com/jntass/Nginx_Tassl)

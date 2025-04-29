FROM debian:bullseye AS builder

# 设置工作目录
WORKDIR /root

# 安装依赖
RUN apt-get update && apt-get install -y \
    make \
    git \
    build-essential \
    libpcre3-dev \
    zlib1g-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth=1 https://github.com/jntass/TASSL-1.1.1.git \
    && git clone --depth=1 https://github.com/jntass/Nginx_Tassl.git \
    && openssl rand -writerand /root/.rnd

# 编译和安装Nginx
RUN cd /root/Nginx_Tassl \
    && ./configure --with-http_ssl_module --with-stream --with-stream_ssl_module  \
        --with-http_auth_request_module --with-http_v2_module \
        --with-http_dav_module --with-openssl=/root/TASSL-1.1.1 \
        --prefix=/usr/local/nginx \
    && make -j$(nproc) \
    && make install

# 配置证书
RUN cp -r /root/TASSL-1.1.1/tassl_demo /usr/local/ \
    && cp /root/TASSL-1.1.1/tassl_demo/cert/openssl.cnf / \
    && cd /usr/local/tassl_demo/cert \
    && sed -i 's/server sign (SM2)/localhost/g' gen_sm2_cert.tmpl \
    && sed -i 's/server enc (SM2)/localhost/g' gen_sm2_cert.tmpl \
    && sed -i 's/client sign (SM2)/localhost/g' gen_sm2_cert.tmpl \
    && chmod +x gen_sm2_cert.tmpl \
    && OPENSSL_DIR=/root/TASSL-1.1.1/.openssl/ ./gen_sm2_cert.tmpl 

    # 准备依赖库
RUN  mkdir /tmp/so \
    && cd /usr/lib/*-linux-*/ \
    && cp libpcre.* /tmp/so

FROM debian:bullseye-slim

# 复制所需文件和依赖库
COPY --from=builder /usr/local/nginx /usr/local/nginx
COPY --from=builder /usr/local/tassl_demo/cert/certs /usr/local/tassl_demo/cert/certs
COPY --from=builder /tmp/so/ /tmp/so/ 
COPY nginx.conf /usr/local/nginx/conf/nginx.conf

RUN cp /tmp/so/* /usr/lib/*-linux-*/ \
    && rm -rf /tmp/so

EXPOSE 80 443

CMD ["/usr/local/nginx/sbin/nginx", "-c", "/usr/local/nginx/conf/nginx.conf"]


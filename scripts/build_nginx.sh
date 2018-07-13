#!/bin/bash
# Build NGINX and modules on Heroku.
# This program is designed to run in a web dyno provided by Heroku.
# We would like to build an NGINX binary for the builpack on the
# exact machine in which the binary will run.
# Our motivation for running in a web dyno is that we need a way to
# download the binary once it is built so we can vendor it in the buildpack.
#
# Once the dyno has is 'up' you can open your browser and navigate
# this dyno's directory structure to download the nginx binary.

NGINX_VERSION=${NGINX_VERSION-1.9.5}
PCRE_VERSION=${PCRE_VERSION-8.37}
HEADERS_MORE_VERSION=${HEADERS_MORE_VERSION-0.261}
GOOGLE_MODULE_VERSION=${GOOGLE_MODULE_VERSION-0.2.0}

nginx_tarball_url=http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz
pcre_tarball_url=http://iweb.dl.sourceforge.net/project/pcre/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.bz2
headers_more_nginx_module_url=https://github.com/openresty/headers-more-nginx-module/archive/v${HEADERS_MORE_VERSION}.tar.gz
ngx_http_google_filter_module_url=https://github.com/cuber/ngx_http_google_filter_module/archive/${GOOGLE_MODULE_VERSION}.tar.gz
ngx_http_substitutions_filter_module_url=https://github.com/yaoweibin/ngx_http_substitutions_filter_module/archive/v0.6.4.tar.gz

temp_dir=$(mktemp -d /tmp/nginx.XXXXXXXXXX)

echo "Serving files from /tmp on $PORT"
cd /tmp
python -m SimpleHTTPServer $PORT &

cd $temp_dir
echo "Temp dir: $temp_dir"

echo "Downloading $nginx_tarball_url"
curl -L $nginx_tarball_url | tar xzv

echo "Downloading $pcre_tarball_url"
(cd nginx-${NGINX_VERSION} && curl -L $pcre_tarball_url | tar xvj )

echo "Downloading $headers_more_nginx_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $headers_more_nginx_module_url | tar xvz )

echo "Downloading $ngx_http_google_filter_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $ngx_http_google_filter_module_url | tar xvz )

echo "Downloading $ngx_http_substitutions_filter_module_url"
(cd nginx-${NGINX_VERSION} && curl -L $ngx_http_substitutions_filter_module_url | tar xvz )
(
	cd nginx-${NGINX_VERSION}
	./configure \
		--with-pcre=pcre-${PCRE_VERSION} \
		--with-http_ssl_module \
		--prefix=/tmp/nginx \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/headers-more-nginx-module-${HEADERS_MORE_VERSION} \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/ngx_http_substitutions_filter_module_url-0.6.4 \
		--add-module=/${temp_dir}/nginx-${NGINX_VERSION}/ngx_http_google_filter_module-${GOOGLE_MODULE_VERSION}
	make install
)

cp /tmp/nginx/sbin/nginx $1

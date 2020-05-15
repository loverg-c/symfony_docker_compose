FROM debian:stretch as custom_apache

ENV HTTPD_PREFIX /usr/local/apache2
ENV PATH $HTTPD_PREFIX/bin:$PATH
RUN mkdir -p "$HTTPD_PREFIX" \
    && chown www-data:www-data "$HTTPD_PREFIX"
WORKDIR $HTTPD_PREFIX

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    apache2 curl \
    && rm -r /var/lib/apt/lists/*

RUN a2enmod proxy_fcgi ssl rewrite proxy proxy_balancer proxy_http proxy_ajp headers

RUN rm -f /run/apache2/apache2.pid

FROM custom_apache

COPY apache2.conf /etc/apache2/apache2.conf

EXPOSE 80 443
CMD apachectl  -DFOREGROUND -e info

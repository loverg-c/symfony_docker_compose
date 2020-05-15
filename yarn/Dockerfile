ARG NODE_VERSION=14.0.0

FROM node:${NODE_VERSION}-alpine AS custom_node

ARG HOST_UID=${HOST_UID:-4000}
ARG HOST_USER=${HOST_USER:-nodummy}
ARG HOST_GROUP=${HOST_GROUP:-1000}

RUN deluser --remove-home node
RUN mkdir /home/${HOST_USER}/

RUN if [ "${HOST_GROUP}" != "root" ]; then (addgroup -g ${HOST_GROUP} docker) ; fi
RUN if [ "${HOST_USER}" != "root" ]; then (adduser -G docker --disabled-password --uid ${HOST_UID} ${HOST_USER}) ; fi
RUN if [ "${HOST_USER}" != "root" ]; then (chown -R ${HOST_UID}:docker /home/${HOST_USER}) ; fi

RUN apk update \
    && apk add --no-cache \
    bash=5.0.11-r1

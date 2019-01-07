FROM node:6

RUN usermod -u 500 node; \
    groupmod -g 500 node; \
    chown node:node -R /home/node

RUN npm install -g coffee cake

WORKDIR /app

ENV PATH /app/node_modules/.bin:$PATH

ARG USERID
RUN adduser --disabled-login --gecos "" username --uid $USERID

USER $USERID

FROM ubuntu:14.04

RUN apt-get update -qq && \
    apt-get install -y nodejs npm && \
    ln -s /usr/bin/nodejs /usr/bin/node

RUN npm install -g coffee-script

RUN mkdir /opt/app
WORKDIR /opt/app
    
RUN npm install chance && \
    npm install should && \
    npm install random-date && \
    npm install csv-parse && \
    npm install async

COPY ["generate.coffee", "/opt/app"]

CMD ["coffee"]

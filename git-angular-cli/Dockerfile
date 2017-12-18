FROM ubuntu:16.04
RUN apt-get update && apt-get install curl -y &&  curl -sL https://deb.nodesource.com/setup_8.x | bash - && apt-get install -y nodejs && apt-get install git -y 

RUN npm install --save -g @angular/cli --unsafe

LABEL Description="Ubuntu / Node / NPM / GIT / Angular-CLI Machine"


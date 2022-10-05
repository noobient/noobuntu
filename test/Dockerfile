FROM ubuntu:22.04

RUN apt -y update
RUN apt -y dist-upgrade
RUN apt -y install git software-properties-common
RUN add-apt-repository -y ppa:ansible/ansible
RUN apt -y update
RUN DEBIAN_FRONTEND=noninteractive apt -y install ansible

RUN git clone https://github.com/noobient/noobuntu.git

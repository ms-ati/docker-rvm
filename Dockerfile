##
# Usage:
#
#     # build the image
#     docker build -t docker-rvm .
#
#     # run console in a container
#     docker run -it docker-rvm bash
#
# Build args:
#
#   * RVM_VERSION (default is 'stable')
#
# Onbuild environment options:
#
#   * RVM_RUBY_VERSIONS
#
#   * RVM_RUBY_DEFAULT
##
FROM ubuntu:16.04

# RVM version to install, default is 'stable'
ARG RVM_VERSION=stable

# RMV user to execute as after RVM is installed
ARG RVM_USER=rvm

# Install dependencies of RVM
RUN apt-get update \
    && apt-get install -y \
       curl \
       git \
       gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Install RVM with gpg verification, see https://rvm.io/rvm/security
RUN gpg2 --quiet --no-tty --logger-fd 1 --keyserver hkp://keys.gnupg.net \
         --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                     7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
    && echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | \
       gpg2 --quiet --no-tty --logger-fd 1 --import-ownertrust \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer.asc \
    && gpg2 --quiet --no-tty --logger-fd 1 --verify rvm-installer.asc \
    && bash rvm-installer ${RVM_VERSION} --with-gems="bundler" \
    && rm rvm-installer rvm-installer.asc

# Switch to a bash login shell to allow simple 'rvm' in RUN commands
SHELL ["/bin/bash", "-l", "-c"]

# See https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd -m --no-log-init -r -g rvm ${RVM_USER}

# Configure rubygems to not install docs
RUN echo "install: --no-document" > ~/.gemrc

# Optional: Child images can automatically install
ONBUILD RUN if [ ! -z "$RVM_RUBY_VERSIONS" ]]; then \
              echo ${RVM_RUBY_VERSIONS} | while read v; do \
                rvm install "${v}" \
                && rvm use "${v}@global" \
                && gem install bundler \
              done \
              && DEFAULT=${RVM_RUBY_DEFAULT:-$(rvm list strings | head -n1)} \
              && [ ! -z "${DEFAULT}" ] && rvm use --default "${DEFAULT}" \
            fi \
            && rvm cleanup all \
            && rm -rf /var/lib/apt/lists/*


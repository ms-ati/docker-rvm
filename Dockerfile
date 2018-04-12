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
#   * RVM_VERSION
#
#   * RVM_USER
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

# RMV user to add to group 'rvm'
ARG RVM_USER=root

# Install dependencies of RVM
RUN apt-get update \
    && apt-get install -y \
       curl \
       git \
       gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Install RVM, see https://rvm.io/rvm/security
RUN gpg2 --keyserver hkp://keys.gnupg.net \
         --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                     7D2BAF1CF37B13E2069D6956105BD0E739499BDB 2>&1 \
    && echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg2 --import-ownertrust \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer.asc \
    && gpg2 --verify rvm-installer.asc 2>&1 \
    && bash rvm-installer ${RVM_VERSION} \
    && rm rvm-installer rvm-installer.asc \
    && usermod -a -G rvm ${RVM_USER}

# Allow RVM to be auto-loaded into bash non-login shells
ENV BASH_ENV "/etc/profile.d/rvm.sh"

# Configure rubygems to not install docs
RUN echo "install: --no-document" > ~/.gemrc

# In child image, install specified Ruby versions
ONBUILD RUN if [ ! -z "$RVM_RUBY_VERSIONS" ]]; then \
              echo ${RVM_RUBY_VERSIONS} | while read v; do \
                rvm install "${v}" && \
                rvm use "${v}@global" && \
                gem install bundler \
              done && \
              DEFAULT=${RVM_RUBY_DEFAULT:-$(rvm list strings | head -n1)} && \
              [ ! -z "${DEFAULT}" ] && rvm use --default "${DEFAULT}" \
            fi

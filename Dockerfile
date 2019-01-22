##
# Usage:
#
#     # build the image
#     docker build -t msati/docker-rvm .
#
#     # run a bash login shell in a container running that image
#     docker run -it msati/docker-rvm bash -l
#
# Build args:
#
#   * RVM_VERSION (default is 'stable')
#
#   * RVM_USER (default is 'rvm')
#
# ONBUILD args in child images:
#
#   * RVM_RUBY_VERSIONS
#
#   * RVM_RUBY_DEFAULT
##
FROM ubuntu:18.04

# RVM version to install
ARG RVM_VERSION=stable
ENV RVM_VERSION=${RVM_VERSION}

# RMV user to create
ARG RVM_USER=rvm
ENV RVM_USER=${RVM_USER}

# Install RVM
RUN apt update \
    && apt install -y \
       curl \
       git \
       gnupg2 \
    && rm -rf /var/lib/apt/lists/*

# Install + verify RVM with gpg (https://rvm.io/rvm/security)
RUN gpg2 --quiet --no-tty --logger-fd 1 --keyserver hkp://keys.gnupg.net \
         --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                     7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
    && echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | \
       gpg2 --quiet --no-tty --logger-fd 1 --import-ownertrust \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer \
    && curl -sSO https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer.asc \
    && gpg2 --quiet --no-tty --logger-fd 1 --verify rvm-installer.asc \
    && bash rvm-installer ${RVM_VERSION} \
    && rm rvm-installer rvm-installer.asc \
    && echo "bundler" >> /usr/local/rvm/gemsets/global.gems \
    && echo "rvm_silence_path_mismatch_check_flag=1" >> /etc/rvmrc \
    && echo "install: --no-document" > /etc/gemrc

# Workaround tty check, see https://github.com/hashicorp/vagrant/issues/1673#issuecomment-26650102
RUN sed -i 's/^mesg n/tty -s \&\& mesg n/g' /root/.profile

# Switch to a bash login shell to allow simple 'rvm' in RUN commands
SHELL ["/bin/bash", "-l", "-c"]

# Optional: child images can change to this user, or add 'rvm' group to other user
# see https://docs.docker.com/develop/develop-images/dockerfile_best-practices/#user
RUN useradd -m --no-log-init -r -g rvm ${RVM_USER}

# Optional: child images can set Ruby versions to install (whitespace-separated)
ONBUILD ARG RVM_RUBY_VERSIONS

# Optional: child images can set default Ruby version (default is first version)
ONBUILD ARG RVM_RUBY_DEFAULT

# Child image runs this only if RVM_RUBY_VERSIONS is defined as ARG before the FROM line
ONBUILD RUN if [ ! -z "${RVM_RUBY_VERSIONS}" ]; then \
              VERSIONS="$(echo "${RVM_RUBY_VERSIONS}" | sed -E -e 's/\s+/\n/g')" \
              && for v in ${VERSIONS}; do \
                   echo "== docker-rvm: Installing ${v} ==" \
                   && rvm install ${v}; \
                 done \
              && DEFAULT=${RVM_RUBY_DEFAULT:-$(echo "${VERSIONS}" | head -n1)} \
              && echo "== docker-rvm: Setting default ${DEFAULT} ==" \
              && rvm use --default "${DEFAULT}"; \
            fi \
            && rvm cleanup all \
            && rm -rf /var/lib/apt/lists/*

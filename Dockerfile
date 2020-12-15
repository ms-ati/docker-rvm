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
# Optional: child images can change to this user, or add 'rvm' group to other user
ARG RVM_USER=rvm
ENV RVM_USER=${RVM_USER}

# Install RVM dependencies
RUN sed -i 's/^mesg n/tty -s \&\& mesg n/g' ~/.profile \
 && sed -i 's~http://archive\(\.ubuntu\.com\)/ubuntu/~mirror://mirrors\1/mirrors.txt~g' /etc/apt/sources.list \
 && export DEBIAN_FRONTEND=noninteractive \
 && apt-get update -qq \
 && apt-get install -qy --no-install-recommends \
       ca-certificates \
 && apt-get install -qy --no-install-recommends \
       curl \
       dirmngr \
       git \
       gnupg2 \
 && rm -rf /var/lib/apt/lists/*

# Install + verify RVM with gpg (https://rvm.io/rvm/security)
RUN mkdir ~/.gnupg \
 && chmod 700 ~/.gnupg \
 && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
 && gpg2 --quiet --no-tty --keyserver hkp://pool.sks-keyservers.net \
         --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
                     7D2BAF1CF37B13E2069D6956105BD0E739499BDB \
 && ( echo 409B6B1796C275462A1703113804BB82D39DC0E3:6: | gpg2 --import-ownertrust ) \
 && ( echo 7D2BAF1CF37B13E2069D6956105BD0E739499BDB:6: | gpg2 --import-ownertrust ) \
 && curl -sSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer -o rvm-installer \
 && curl -sSL https://raw.githubusercontent.com/rvm/rvm/${RVM_VERSION}/binscripts/rvm-installer.asc -o rvm-installer.asc \
 && gpg2 --verify rvm-installer.asc rvm-installer \
 && bash rvm-installer \
 && rm rvm-installer \
 && echo "rvm_autoupdate_flag=2" >> /etc/rvmrc \
 && echo "rvm_silence_path_mismatch_check_flag=1" >> /etc/rvmrc \
 && echo "install: --no-document" > /etc/gemrc \
 && useradd -m --no-log-init -r -g rvm ${RVM_USER}

# Switch to a bash login shell to allow simple 'rvm' in RUN commands
SHELL ["/bin/bash", "-l", "-c"]

# Optional: child images can set Ruby versions to install (whitespace-separated)
ONBUILD ARG RVM_RUBY_VERSIONS

# Optional: child images can set default Ruby version (default is first version)
ONBUILD ARG RVM_RUBY_DEFAULT

# Child image runs this only if RVM_RUBY_VERSIONS is defined as ARG before the FROM line
ONBUILD RUN if [ ! -z "${RVM_RUBY_VERSIONS}" ]; then \
              for v in $( echo ${RVM_RUBY_VERSIONS} | sed -E 's/[[:space:]]+/\n/g' ); do \
                echo "== docker-rvm: Installing ${v} ==" \
                && rvm install ${v}; \
              done \
              && echo "== docker-rvm: Setting default ${RVM_RUBY_DEFAULT} ==" \
              && rvm use --default ${RVM_RUBY_DEFAULT:-${RVM_RUBY_VERSIONS/[[:space:]]*/}} \
              && rvm cleanup all \
              && rm -rf /var/lib/apt/lists/*; \
            fi

CMD ["/bin/bash", "-l"]

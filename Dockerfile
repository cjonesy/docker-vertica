FROM ubuntu:14.04
MAINTAINER cjonesy

# ------------------------------------------------------------------------------
# Update the image and prepare for Vertica install
# ------------------------------------------------------------------------------
RUN apt-get update -y \
&&  apt-get upgrade -y \
&&  apt-get install -y openssh-server \
                       openssh-client \
                       mcelog \
                       gdb \
                       sysstat \
                       dialog \
                       curl \
&&  apt-get clean \
&&  curl -o /usr/local/bin/gosu \
         -SL 'https://github.com/tianon/gosu/releases/download/1.1/gosu' \
&&  chmod +x /usr/local/bin/gosu \
&&  locale-gen en_US en_US.UTF-8 \
&&  dpkg-reconfigure -f noninteractive locales

# ------------------------------------------------------------------------------
# Create users, and ensure they use bash for shell (required by Vertica
# ------------------------------------------------------------------------------
RUN groupadd -r verticadba \
&&  useradd -r -m -g verticadba dbadmin \
&&  chsh -s /bin/bash dbadmin \
&&  chsh -s /bin/bash root \
&&  rm /bin/sh \
&&  ln -s /bin/bash /bin/sh \
&&  echo "dbadmin -       nice    0" >> /etc/security/limits.conf \
&&  echo "dbadmin -       nofile  65536" >> /etc/security/limits.conf

ENV SHELL "/bin/bash"

# ------------------------------------------------------------------------------
# Install Vertica
# ------------------------------------------------------------------------------
ADD vertica_*_amd64.deb /tmp/vertica.deb
RUN dpkg -i /tmp/vertica.deb \
&&  rm -f /tmp/vertica.deb \
&&  /opt/vertica/sbin/install_vertica --license CE \
                                      --accept-eula \
                                      --hosts 127.0.0.1 \
                                      --dba-user-password-disabled \
                                      --failure-threshold NONE \
                                      --no-system-configuration

# ------------------------------------------------------------------------------
# Create database
# ------------------------------------------------------------------------------
USER dbadmin
RUN /opt/vertica/bin/admintools -t create_db \
                                -s localhost \
                                --skip-fs-checks \
                                -d docker \
                                -c /home/dbadmin/docker/catalog \
                                -D /home/dbadmin/docker/data

# ------------------------------------------------------------------------------
# Python Eggs
# ------------------------------------------------------------------------------
USER root
RUN mkdir /tmp/.python-eggs \
&&  chown -R dbadmin /tmp/.python-eggs
ENV PYTHON_EGG_CACHE /tmp/.python-eggs

# ------------------------------------------------------------------------------
# Data Directory
# ------------------------------------------------------------------------------
ENV VERTICADATA /home/dbadmin/docker
VOLUME  /home/dbadmin/docker

# ------------------------------------------------------------------------------
# Start Vertica
# ------------------------------------------------------------------------------
ADD ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 5433


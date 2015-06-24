# Riak

FROM phusion/baseimage:0.9.14

# Environmental variables
ENV RIAK_VERSION 2.0.5-1

# Install Java 7
RUN sed -i.bak 's/main$/main universe/' /etc/apt/sources.list
RUN apt-get update -qq && apt-get install -y software-properties-common && \
    apt-add-repository ppa:webupd8team/java -y && apt-get update -qq && \
    echo oracle-java7-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections && \
    apt-get install -y oracle-java7-installer

# Install Riak
RUN curl https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | bash
RUN apt-get install -y riak=${RIAK_VERSION}

# Setup the Riak service
RUN mkdir -p /etc/service/riak
ADD bin/riak.sh /etc/service/riak/run

# Setup automatic clustering
ADD bin/automatic_clustering.sh /etc/my_init.d/99_automatic_clustering.sh

# Tune Riak configuration settings for the container
ADD etc/riak.conf /etc/riak/riak.conf

# Make Riak's data and log directories volumes
VOLUME /var/lib/riak
VOLUME /var/log/riak

# Open ports for HTTP and Protocol Buffers
EXPOSE 8098 8087

# Enable insecure SSH key
# See: https://github.com/phusion/baseimage-docker#using_the_insecure_key_for_one_container_only
RUN /usr/sbin/enable_insecure_key

# Cleanup
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Leverage the baseimage-docker init system
CMD ["/sbin/my_init", "--quiet"]

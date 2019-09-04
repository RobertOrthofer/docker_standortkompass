FROM ubuntu:18.04
MAINTAINER Jan Nonnen <helvalius@gmail.com>
# Define the OSM argument, use austria as default
ARG OSM=http://download.geofabrik.de/europe/austria-latest.osm.pbf

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

# Install basic software
RUN apt-get -y install wget


# Note: libgeos++-dev is included here too (the nominatim install page suggests installing it if there is a problem with the 'pear install DB' below - it seems safe to install it anyway)
RUN apt-get -y install build-essential gcc git osmosis  libxml2-dev libgeos-dev libpq-dev libbz2-dev libtool cmake libproj-dev proj-bin libgeos-c1v5 libgeos++-dev libexpat1-dev

# Install Boost (required by osm2pqsql)
RUN apt-get -y install autoconf make g++ libboost-dev libboost-system-dev libboost-filesystem-dev libboost-thread-dev lua5.2 liblua5.2-dev

# Install PHP7
RUN apt-get -y install php7.2 php-pear php7.2-pgsql php7.2-json php7.2-intl php-db

# From the website "If you plan to install the source from github, the following additional packages are needed:"
# RUN apt-get -y install git autoconf-archive

# Install Postgres, PostGIS and dependencies
RUN apt-get -y install postgresql postgis postgresql-contrib postgresql-server-dev-10

# Work around for AUFS bug as per https://github.com/docker/docker/issues/783#issuecomment-56013588
RUN mkdir /etc/ssl/private-copy; mv /etc/ssl/private/* /etc/ssl/private-copy/; rm -r /etc/ssl/private; mv /etc/ssl/private-copy /etc/ssl/private; chmod -R 0700 /etc/ssl/private; chown -R postgres /etc/ssl/private

# Some additional packages that may not already be installed
# bc is needed in configPostgresql.sh
RUN apt-get -y install bc

# Install Apache
RUN apt-get -y install apache2

# Add Protobuf support
RUN apt-get -y install libprotobuf-c0-dev protobuf-c-compiler

RUN apt-get  -y install sudo

#

RUN pear install DB
RUN useradd -m -p password1234 nominatim
RUN mkdir -p /app/git/
RUN git clone --recursive https://github.com/twain47/Nominatim.git /app/git/
RUN mkdir -p /app/nominatim

WORKDIR /app/nominatim

RUN cmake /app/git/
RUN make

# Configure postgresql
RUN service postgresql start && \
  pg_dropcluster --stop 10 main
RUN service postgresql start && \
  pg_createcluster --start -e UTF-8 10 main

RUN sudo -u postgres /usr/lib/postgresql/10/bin/pg_ctl start -w -D /etc/postgresql/10/main/ && \
  cat /var/log/postgresql/postgresql-10-main.log && \
  sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='nominatim'" | grep -q 1 || sudo -u postgres createuser -s nominatim && \
  sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'" | grep -q 1 || sudo -u postgres createuser -SDR www-data && \
  sudo -u postgres psql postgres -c "DROP DATABASE IF EXISTS nominatim"

RUN wget --timestamping --output-document=/app/git/data/country_osm_grid.sql.gz https://www.nominatim.org/data/country_grid.sql.gz
RUN wget --timestamping --output-document=/app/data.pbf $OSM
# RUN wget --output-document=/app/data.pbf http://download.geofabrik.de/europe/luxembourg-latest.osm.pbf
# RUN wget --output-document=/app/data.pbf http://download.geofabrik.de/north-america-latest.osm.pbf
# RUN wget --output-document=/app/data.pbf http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf

WORKDIR /app/nominatim

ADD local.php /app/nominatim/settings/local.php


RUN ./utils/setup.php --help

RUN chown -R nominatim:nominatim /app/nominatim
RUN sudo -u postgres /usr/lib/postgresql/10/bin/pg_ctl start -w -D /etc/postgresql/10/main/ && \
  sudo -u nominatim ./utils/setup.php --osm-file /app/data.pbf --all --threads 2

RUN mkdir -p /var/www/nominatim
RUN cp -R /app/nominatim/website /var/www/nominatim/
RUN cp -R /app/nominatim/settings /var/www/nominatim/
RUN chown -R nominatim:www-data /var/www/nominatim


# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  trust" >> /etc/postgresql/10/main/pg_hba.conf

# And add ``listen_addresses`` to ``/etc/postgresql/10/main/postgresql.conf``
RUN echo "listen_addresses='*'" >> /etc/postgresql/10/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

RUN apt-get install -y curl
ADD 400-nominatim.conf /etc/apache2/sites-available/400-nominatim.conf
RUN service apache2 start && \
  a2ensite 400-nominatim.conf && \
  /etc/init.d/apache2 reload

# Expose the /Users/robertHTTP port
EXPOSE 8080


ADD configPostgresql.sh /app/nominatim/configPostgresql.sh
WORKDIR /app/nominatim
RUN chmod +x ./configPostgresql.sh
ADD start.sh /app/nominatim/start.sh
RUN chmod +x /app/nominatim/start.sh

RUN echo "Using OSM URL: "$OSM

CMD /app/nominatim/start.sh

#PHOTON
RUN add-apt-repository ppa:webupd8team/java
RUN apt-get update
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
RUN mkdir /photon
WORKDIR /photon
# Expose Photon Webservice
EXPOSE 2322
RUN wget https://github.com/komoot/photon/releases/download/0.3.0/photon-0.3.0.jar
COPY ./startup.sh /photon/
RUN chmod +x /photon/startup.sh
FROM ubuntu:14.04
MAINTAINER Scott Harvey <scott@civilmaps.com>

#Python installation
RUN sudo apt-get update && apt-get install -y python-pip \
    wget \
    unzip
RUN sudo apt-get install -y software-properties-common

#Install wine
RUN sudo add-apt-repository ppa:ubuntu-wine/ppa
RUN sudo dpkg --add-architecture i386
RUN sudo apt-get update
RUN sudo apt-get install -y wine

#Lastools installation
WORKDIR /
ADD http://www.cs.unc.edu/~isenburg/lastools/download/lastools.zip /home/
#RUN mv lastools.zip home/
RUN unzip /home/lastools.zip
#RUN mv LAStools home/

#Link LAStools
RUN mkdir -p /mfs/tools/
RUN ln -s /home/LAStools /mfs/tools/LAStools

#RUN sudo ldconfig

#Git setup
RUN sudo apt-get install -y git

# Copy over private key, and set permissions for git
RUN mkdir -p /root/.ssh
ADD https://s3-us-west-1.amazonaws.com/solfice-data/564d4480-5cc7-11e5-885d-feff819cdc9f/id_rsa /root/.ssh/
ADD https://s3-us-west-1.amazonaws.com/solfice-data/564d4480-5cc7-11e5-885d-feff819cdc9f/authorized_keys /root/.ssh/
RUN touch /root/.ssh/known_hosts
RUN echo "    StrictHostKeyChecking no" >> /etc/ssh/ssh_config


#mongoDB
RUN sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
RUN sudo apt-get update
RUN sudo apt-get install -y mongodb-10gen
RUN sudo apt-get install -y python-pymongo

#memcached
RUN sudo apt-get install -y memcached
RUN sudo apt-get install -y python-memcache

#Python libraries
RUN sudo apt-get install -y python-numpy \
    python-matplotlib \
    python-opencv

#AWS CLI
RUN pip install -U boto
RUN sudo pip install awscli
ENV AWS_ACCESS_KEY_ID AKIAIZR3P4TBTSYX67HQ
ENV AWS_SECRET_ACCESS_KEY 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
ENV AWS_DEFAULT_REGION us-east-1

#liblas-laszip
ADD http://download.osgeo.org/laszip/laszip-2.1.0.tar.gz /home/
RUN tar xvfz /home/laszip-2.1.0.tar.gz
RUN mv laszip-2.1.0 /home/
RUN mkdir /home/laszip-2.1.0/makefiles
RUN sudo apt-get install -y cmake
RUN cd /home/laszip-2.1.0/makefiles/ && cmake .. && make && sudo make install

RUN wget http://www.cs.unc.edu/~isenburg/lastools/download/data/xyzrgb_manuscript.laz
RUN wine /mfs/tools/LAStools/bin/lasinfo.exe xyzrgb_manuscript.laz

RUN sudo ldconfig

#liblas
RUN git clone git://github.com/libLAS/libLAS.git home/liblas
# RUN sudo apt-get install -y libboost1.55-all-dev
RUN sudo apt-get install -y libboost-all-dev
RUN sudo apt-get install -y libgeos-dev libproj-dev libtiff4-dev libgeotiff-dev
RUN mkdir home/liblas/makefiles
ADD https://raw.githubusercontent.com/NLeSC/pointcloud-benchmark/master/install/centos7/FindPROJ4.cmake home/liblas/cmake/modules/
RUN cd home/liblas/makefiles/ && cmake -G "Unix Makefiles" .. -DWITH_LASZIP=ON -DWITH_PKGCONFIG=ON -DWITH_TESTS=ON && make && sudo make install
# RUN sudo /sbin/ldconfig ##link bindings

#python bindings for liblas
RUN sudo pip install liblas
RUN sudo pip install retrying

#Install PCL
# RUN sudo apt-get install aptitude -y
RUN add-apt-repository ppa:v-launchpad-jochen-sprickerhof-de/pcl
RUN sudo apt-get update -y
RUN sudo apt-get install libpcl-all -y

#GDAL
RUN wget http://download.osgeo.org/gdal/gdal-1.9.0.tar.gz
RUN tar xvfz gdal-1.9.0.tar.gz
RUN cd gdal-1.9.0 && ./configure --with-python && make && sudo make install

#Install points2grid
RUN git clone https://github.com/CRREL/points2grid.git
RUN mv points2grid /opt/
RUN mkdir /opt/points2grid/makefiles/
RUN cd /opt/points2grid/makefiles/ && cmake .. && make && sudo make install

#PDAL
RUN git clone git@github.com:PDAL/PDAL.git pdal
RUN mv pdal /opt/
RUN mkdir /opt/pdal/makefiles/
RUN cd /opt/pdal/makefiles/ && cmake .. && make && sudo make install

RUN sudo ldconfig


RUN sudo apt-get update
RUN sudo pip install geojson
RUN sudo apt-get install -y python-scipy
RUN sudo pip install --user --install-option="--prefix=" -U scikit-learn
RUN sudo apt-get install -y python-vtk
RUN sudo apt-get install -y python-skimage
RUN sudo pip install noise
RUN sudo apt-get install -y python-pyproj
RUN sudo pip install mock
RUN sudo pip install pandas


# #Install htop
RUN sudo apt-get install htop

#RUN mkdir -p /tmp/lidar-storage/
# #RUN mkdir -p /home/lidar-storage/
# RUN ln -s /tmp/lidar-storage /home/lidar-storage



#Get git repo and link to /mfs/src/prod
RUN git clone git@github.com:civilmaps/solfice.git
RUN mv solfice home/solfice
RUN mkdir -p /mfs/src
RUN ln -s /home/solfice /mfs/src/prod

VOLUME /var/log/docker

ADD start.sh /start.sh
RUN chmod +x /start.sh

#CMD ["python","/mfs/src/prod/tests/tiling_te

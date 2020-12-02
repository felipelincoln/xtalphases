FROM centos:7
MAINTAINER "Billy K. Poon" bkpoon@lbl.gov

# builder
ARG BUILDER=cctbx

# number of processors for building
ARG NCPU=4

# update OS and install system packages for building
RUN yum -y update && \
    yum -y install gcc gcc-c++ autoconf libtool make python wget git svn \
        zlib zlib-devel bzip2 bzip2-devel \
        libX11 libX11-devel libXext libXext-devel \
        mesa-libGL mesa-libGL-devel mesa-libGLU mesa-libGLU-devel

# get bootstrap.py
RUN wget "https://raw.githubusercontent.com/cctbx/cctbx_project/master/libtbx/auto_build/bootstrap.py"

# get sources
RUN python bootstrap.py hot update --builder=${BUILDER}

# build dependencies
RUN python bootstrap.py base --builder=${BUILDER} --nproc=${NCPU}

# build
RUN python bootstrap.py build --builder=${BUILDER} --nproc=${NCPU}

# jupyter stage
FROM jupyter/scipy-notebook:latest

USER root

RUN mkdir /build /base /modules

COPY --from=0 /build/ /build/
COPY --from=0 /base/ /base/
COPY --from=0 /modules/ /modules/

RUN conda install yellowbrick xgboost conda-build -y

COPY ./ /

RUN cd / && conda develop .

RUN mv /exploration/* ./work/

USER jovyan

ENV PATH=$PATH:/build/bin/

CMD ["jupyter-lab"]

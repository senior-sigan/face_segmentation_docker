FROM nvidia/cuda:8.0-cudnn6-devel-ubuntu16.04
MAINTAINER Ilya Siganov <ilya.blan4@gmail.com>
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        wget \
        g++ \
        nano \
        curl \
        autoconf \
        automake \
        libtool \
        make \
        g++ \
        gfortran \
        unzip \
        autoconf \
        pkg-config \
        protobuf-compiler \
        python-dev \
        python-pip \
        python-setuptools \
        python-tk \
        libjpeg8-dev \
        libpng-dev \
        libtiff5-dev \
        libgphoto2-dev \
        libboost-all-dev \
        libatlas-base-dev \
        libgflags-dev \
        libopenblas-dev \
        liblapack-dev \
        libgoogle-glog-dev \
        libleveldb-dev \
        liblmdb-dev \
        libsnappy-dev \
        libprotobuf-dev \
        libhdf5-serial-dev \
        x-window-system \
        binutils \
        mesa-utils \
        module-init-tools \
        doxygen && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/*

ADD nvidia-driver.run /tmp/nvidia-driver.run
RUN sh /tmp/nvidia-driver.run -a -N --ui=none --no-kernel-module && \
    rm /tmp/nvidia-driver.run

RUN curl -O https://bootstrap.pypa.io/get-pip.py && \
    python get-pip.py && \
    rm get-pip.py

RUN pip --no-cache-dir install --upgrade ipython && \
    pip --no-cache-dir install \
        pyopenssl \
        ndg-httpsclient \
        pyasn1 \
        matplotlib \
        h5py \
        scipy \
        numpy \
        Cython \
        ipykernel \
        jupyter \
        path.py \
        Pillow \
        pygments \
        six \
        sphinx \
        wheel \
        zmq \
        flask \
        && \
    python -m ipykernel.kernelspec

RUN git clone --depth 1 https://github.com/opencv/opencv.git /root/opencv && \
    cd /root/opencv && \
    mkdir build && \
    cd build && \
    cmake .. && \
    make -j"$(nproc)"  && \
    make install && \
    ldconfig && \
    cd /root && rm -rf /root/opencv \
    echo 'ln /dev/null /dev/raw1394' >> ~/.bashrc

# Install HDF5 (for protobuf)
RUN cd /root && \
    wget https://support.hdfgroup.org/ftp/HDF5/current18/src/hdf5-1.8.20.tar.bz2 && \
    tar -jxf hdf5-1.8.20.tar.bz2 && \
    cd hdf5-1.8.20 && \
    ./configure --prefix=/usr/local --enable-cxx --enable-fortran --enable-production && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig
        
# Install Protobuf
# RUN git clone https://github.com/google/protobuf.git /root/protobuf && \
#     cd /root/protobuf && \
#     git checkout tags/v3.6.1 && \
#     ./autogen.sh && \
#     ./configure --prefix=/usr/local && \
#     make -j"$(nproc)" && \
#     make install && \
#     ldconfig

RUN git clone https://github.com/NVIDIA/nccl.git && cd nccl/src && \
    make -j"$(nproc)" install

# Caffe
ENV CAFFE_ROOT=/opt/caffe
WORKDIR $CAFFE_ROOT

ENV CLONE_TAG=1.0

RUN git clone -b ${CLONE_TAG} --depth 1 https://github.com/BVLC/caffe.git . && \
    pip install --upgrade pip && \
    cd python && for req in $(cat requirements.txt) pydot; do pip install $req; done && cd .. && \
    mkdir build && cd build && \
    cmake -DUSE_CUDNN=1 -DUSE_NCCL=1 -DCMAKE_CXX_STANDARD=11 .. && \
    make -j"$(nproc)"

ENV PYCAFFE_ROOT $CAFFE_ROOT/python
ENV PYTHONPATH $PYCAFFE_ROOT:$PYTHONPATH
ENV PATH $CAFFE_ROOT/build/tools:$PYCAFFE_ROOT:$PATH
RUN echo "$CAFFE_ROOT/build/lib" >> /etc/ld.so.conf.d/caffe.conf && ldconfig

RUN cd /opt/caffe && \
    protoc src/caffe/proto/caffe.proto --cpp_out=. && \
    mkdir include/caffe/proto && \
    mv src/caffe/proto/caffe.pb.h include/caffe/proto

##############

# Face Segmentation
RUN git clone https://github.com/YuvalNirkin/face_segmentation.git /root/face_segmentation && \
    cd /root/face_segmentation && \
    mkdir build && \
    cd build && \
    cmake -DCMAKE_CXX_STANDARD=14 .. && \
    make -j"$(nproc)" && \
    make install && \
    ldconfig

RUN ldconfig && ldconfig -p | grep dl

ADD face_seg_fcn8s_300_no_aug/face_seg_fcn8s_300.caffemodel /root/face_segmentation/data/face_seg_fcn8s.caffemodel
ADD face_seg_fcn8s_300_no_aug/face_seg_fcn8s_300_deploy.prototxt /root/face_segmentation/data/face_seg_fcn8s_deploy.prototxt

WORKDIR /root

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]


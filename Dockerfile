# ============================================================
#  Jetson Orin Nano – ORB-SLAM3 + ROS2 Humble + CUDA 12.6
# ============================================================

FROM nvcr.io/nvidia/12.6.11-devel:12.6.11-devel-aarch64-ubuntu22.04 AS base-arm64

# ---- Prevent tzdata/locale prompts ----
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# ---- Step 1: minimal utilities so we can add external repos ----
RUN apt-get update && apt-get install -y \
    curl \
    gnupg2 \
    lsb-release \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ---- Step 2: add ROS 2 Humble repository and key ----
RUN curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg \
 && echo "deb [arch=arm64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] \
      http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
      > /etc/apt/sources.list.d/ros2.list

# ---- Step 3: install ROS 2 + build tools + dependencies ----
RUN apt-get update && apt-get install -y \
    ros-humble-ros-base \
    build-essential \
    cmake \
    git \
    wget \
    unzip \
    pkg-config \
    python3-dev \
    libboost-all-dev \
    libdbus-1-dev \
    libgtk-3-dev \
    python3-pip \
    python3-colcon-common-extensions \
    python3-rosdep \
    python3-vcstool \
    python3-ament-package \
    locales \
    tzdata \

    # OpenCV dependencies
    python3-numpy \
    # Pangolin dependencies
    libgl1-mesa-dev \
    libglew-dev \
    libpython3-dev \
    libeigen3-dev \
    apt-transport-https \
    ca-certificates\
    software-properties-common \

 && locale-gen en_US.UTF-8 \
 && rm -rf /var/lib/apt/lists/*

RUN apt update

# Build OpenCV
RUN apt-get install -y python3-dev python3-numpy python2-dev
RUN apt-get install -y libavcodec-dev libavformat-dev libswscale-dev
RUN apt-get install -y libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev
RUN apt-get install -y libgtk-3-dev

RUN cd /tmp && git clone https://github.com/opencv/opencv.git && \
    cd opencv && \
    git checkout 4.4.0 && mkdir build && cd build && \
    cmake -D CMAKE_BUILD_TYPE=Release -D BUILD_EXAMPLES=OFF  -D BUILD_DOCS=OFF -D BUILD_PERF_TESTS=OFF -D BUILD_TESTS=OFF -D CMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j8 && make install && \
    cd / && rm -rf /tmp/opencv
    
# Build Pangolin
RUN cd /tmp && git clone https://github.com/stevenlovegrove/Pangolin && \
    cd Pangolin && git checkout v0.9.1 && mkdir build && cd build && \
    cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_FLAGS=-std=c++14 -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j8 && make install && \
    cd / && rm -rf /tmp/Pangolin

RUN apt-get update && apt-get install ros-humble-pcl-ros tmux -y
RUN apt-get install ros-humble-nav2-common x11-apps nano -y
RUN apt-get install -y gdb gdbserver ros-humble-rmw-cyclonedds-cpp ros-humble-cv-bridge ros-humble-image-transport ros-humble-image-common ros-humble-vision-opencv

RUN apt-get install ros-humble-sensor-msgs ros-humble-geometry-msgs ros-humble-nav-msgs ros-humble-tf2-ros

# Native Intel RealSense SDK (provides C++ headers and CMake config)
RUN apt-get update && apt-get install -y \
    librealsense2-utils \
    librealsense2-dev \
    librealsense2-dbg \
    ros-humble-realsense2-camera

# ---- Initialise rosdep ----
RUN rosdep init && rosdep update


# ============================================================
# Copy your workspace (HOST side)
# Make sure you run: git submodule update --init --recursive
# before building so sources are present
# ============================================================
# IMPORTANT: Docker context must include the ros2_test workspace
WORKDIR /root
COPY ros2_test /root/ros2_test

# ---- Build ORB-SLAM3 + ROS2 wrapper ----
# (mirrors the “working” Dockerfile pattern)
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
    rosdep install -r --from-paths /root/ros2_test/src --ignore-src -y --rosdistro humble && \
    cd /root/ros2_test && colcon build --symlink-install"

# ---- Create workspace ----
#RUN mkdir -p /root/colcon_ws/src
#WORKDIR /root/colcon_ws/src

# ---- Clone ORB-SLAM3 core ----
#RUN git clone https://github.com/zang09/ORB-SLAM3-STEREO-FIXED.git ORB_SLAM3

# ---- Clone ROS2 wrapper (example fork) ----
#RUN git clone https://github.com/zang09/ORB_SLAM3_ROS2.git orbslam3_ros2

# ---- Build and INSTALL ORB-SLAM3 core ----
#WORKDIR /root/colcon_ws/src/ORB_SLAM3
#RUN chmod +x build.sh && ./build.sh Release && \
#    cmake -S . -B build-release -DCMAKE_BUILD_TYPE=Release && \
#    cmake --build build-release -j$(nproc)
    
# Tell CMake where to find the installed config
#ENV CMAKE_PREFIX_PATH=/root/colcon_ws/install/orb_slam3:$CMAKE_PREFIX_PATH

# ---- Build ROS 2 wrapper ----
# Build the wrapper and point to the *build* tree
#WORKDIR /root/colcon_ws
#RUN /bin/bash -c "source /opt/ros/humble/setup.bash && \
#    colcon build --symlink-install \
#      --cmake-args -DORB_SLAM3_DIR=/root/colcon_ws/src/ORB_SLAM3/build-release"

# ---- Source environment automatically when container starts ----
RUN echo 'source /opt/ros/humble/setup.bash'  >> /root/.bashrc && \
    echo 'source /root/ros2_test/install/setup.bash' >> /root/.bashrc



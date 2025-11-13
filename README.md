# orbslam3_ros2_jetson
This is orbslam3 compiled as a docker image to run on the Jetson Orin Nano. I developed this for my honours thesis at The Unversity of Sydney. This is my attempt to compare and contrast with cuSLAM on the Jetson Orin Nano and CUDIFY the ORBSLAM3 pipeline, for use on Drones, Robots etc.

## Testing and Implementation
This was sucessfully tested and run on the Jetson Orin Nano

## Setting this up correctly
I have nested a branch of this repo inside this repo. To correctly clone please clone this
```bash
  git clone --recursive https://github.com/dboieng/orbslam3_ros2_jetson.git
  cd orbslam3_ros2_jetson
```
Then 
```bash
  sudo docker build -t orbslam3_ros2_jetson:latest .
```
Start it


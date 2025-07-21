#!/bin/bash

# GLIM Startup Script (CPU-only for Pi 5 with Iridescence viewer)
# This script starts GLIM with the correct parameters for Raspberry Pi 5

echo "Starting GLIM LiDAR-IMU Mapping (CPU-only for Pi 5 with Iridescence viewer)..."

# Start GLIM with ROS2 using optimized Pi 5 configuration and virtual framebuffer for viewer
xvfb-run -a ros2 run glim_ros glim_rosnode \
    --ros-args \
    -p config_path:=/home/ubpi5/glim_cfg \
    -p points_topic:=/livox/lidar \
    -p imu_topic:=/livox/imu

echo "GLIM started successfully!" 
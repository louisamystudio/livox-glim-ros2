#!/bin/bash

# Complete startup script for Livox Avia + GLIM mapping system with CUSTOM CONFIG
# This script uses the modified configurations in ~/glim/config/

echo "Starting Livox Avia + GLIM Mapping System with Custom Config..."

# Source ROS environments
source /opt/ros/jazzy/setup.bash
source /home/ubpi5/ws_livox/install/setup.bash

# Kill any existing processes
echo "Cleaning up existing processes..."
pkill -f "glim" || true
pkill -f "livox" || true
pkill -f "static_transform_publisher" || true
sleep 2

# Start static transform publisher (base_link -> lidar)
echo "Starting static transform publisher..."
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 base_link lidar &
STATIC_TF_PID=$!
sleep 1

# Start Livox driver
echo "Starting Livox Avia driver..."
ros2 run livox_ros2_driver livox_ros2_driver_node \
    --ros-args \
    -p user_config_path:=/home/ubpi5/glim/config/livox_avia_config.json \
    -p frame_id:=lidar \
    -p publish_freq:=10.0 \
    -p publish_imu:=true &
LIVOX_PID=$!
sleep 3

# Wait for Livox to start publishing
echo "Waiting for Livox to start publishing..."
timeout 10 bash -c 'until ros2 topic hz /livox/lidar --window 1 2>/dev/null | grep -q "average rate"; do sleep 1; done'

# Start GLIM with CUSTOM CONFIG PATH
echo "Starting GLIM mapping with custom configuration..."
DISPLAY=:0 ros2 run glim_ros glim_rosnode \
    --ros-args \
    -p config_path:=/home/ubpi5/glim/config \
    -p points_topic:=/livox/lidar \
    -p imu_topic:=/livox/imu \
    -p acc_scale:=9.80665 \
    -p base_frame_id:=base_link \
    -p odom_frame_id:=odom \
    -p map_frame_id:=map \
    -p publish_tf:=true &
GLIM_PID=$!

echo "All components started with custom configuration!"
echo "Config Path: /home/ubpi5/glim/config"
echo "Livox PID: $LIVOX_PID"
echo "GLIM PID: $GLIM_PID"
echo "Static TF PID: $STATIC_TF_PID"

# Function to clean up on exit
cleanup() {
    echo "Shutting down..."
    kill $GLIM_PID 2>/dev/null
    kill $LIVOX_PID 2>/dev/null
    kill $STATIC_TF_PID 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Wait for processes
echo "System running with custom config. Press Ctrl+C to stop."
wait 
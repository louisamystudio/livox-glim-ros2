#!/bin/bash

echo "===== GLIM + Livox Avia + RViz (Fixed DDS) ====="
echo "Killing existing processes..."
pkill -f "rviz2|glim_rosnode|livox_ros2_driver|static_transform_pub" || true
sleep 2

# Setup environment
source /opt/ros/jazzy/setup.bash
source ~/ws_livox/install/setup.bash

# CRITICAL: Set Fast DDS configuration to prevent segfault
export FASTRTPS_DEFAULT_PROFILES_FILE=/home/ubpi5/glim/config/fastdds_profile.xml
export RMW_IMPLEMENTATION=rmw_fastrtps_cpp

# Increase system buffer sizes for large data
echo "Setting system buffer sizes..."
sudo sysctl -w net.core.rmem_max=134217728
sudo sysctl -w net.core.wmem_max=134217728
sudo sysctl -w net.core.rmem_default=134217728
sudo sysctl -w net.core.wmem_default=134217728

echo "Starting static transform publisher..."
# Map -> Odom transform (identity)
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 map odom &
STATIC_TF_PID=$!

# LiDAR -> IMU transform (identity for Livox Avia - they're colocated)
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 lidar imu &
STATIC_TF_IMU_PID=$!

echo "Starting Livox Avia driver with proper configuration..."
# Use PointCloud2 format (xfer_format=0) for full IMU 200Hz rate
ros2 run livox_ros2_driver livox_ros2_driver_node \
    --ros-args \
    -p user_config_path:=/home/ubpi5/glim/config/livox_avia_config.json \
    -p xfer_format:=0 \
    -p publish_freq:=10.0 \
    -p frame_id:=lidar &
LIVOX_PID=$!

# Wait for driver to initialize
echo "Waiting for Livox driver to initialize..."
sleep 10

# Check if topics are publishing
echo "Checking Livox topics..."
if ros2 topic list | grep -q "/livox/lidar"; then
    echo "✓ /livox/lidar topic found"
    ros2 topic hz /livox/lidar --window 10 | grep -m1 "average rate" || echo "WARNING: /livox/lidar topic not publishing!"
else
    echo "ERROR: /livox/lidar topic not found!"
fi

if ros2 topic list | grep -q "/livox/imu"; then
    echo "✓ /livox/imu topic found"
    ros2 topic hz /livox/imu --window 10 | grep -m1 "average rate" || echo "WARNING: /livox/imu topic not publishing!"
else
    echo "ERROR: /livox/imu topic not found!"
fi

echo "Starting GLIM node with custom configuration..."
FASTRTPS_DEFAULT_PROFILES_FILE=/home/ubpi5/glim/config/fastdds_profile.xml \
DISPLAY=:0 ros2 run glim_ros glim_rosnode \
    --ros-args \
    -p config_path:=$(realpath /home/ubpi5/glim/config) \
    -p points_topic:=/livox/lidar \
    -p imu_topic:=/livox/imu \
    -p acc_scale:=9.80665 \
    -p base_frame_id:=base_link &
GLIM_PID=$!

# Wait for GLIM to initialize
echo "Waiting for GLIM to initialize..."
sleep 10

echo "Checking GLIM topics..."
ros2 topic list | grep glim

echo "Starting RViz with GLIM configuration..."
rviz2 -d /home/ubpi5/glim/config/glim_ros.rviz &
RVIZ_PID=$!

echo "===== All processes started ====="
echo "Static TF PID: $STATIC_TF_PID"
echo "Livox PID: $LIVOX_PID"
echo "GLIM PID: $GLIM_PID"
echo "RViz PID: $RVIZ_PID"

# Monitor processes
monitor_processes() {
    while true; do
        sleep 15
        echo "=== Process Status at $(date) ==="
        
        # Check each process
        if ! kill -0 $LIVOX_PID 2>/dev/null; then
            echo "ERROR: Livox driver has crashed!"
            break
        fi
        
        if ! kill -0 $GLIM_PID 2>/dev/null; then
            echo "ERROR: GLIM has crashed!"
            break
        fi
        
        # Check topic status
        echo -n "/livox/lidar: "
        timeout 2 ros2 topic hz /livox/lidar 2>&1 | grep -m1 "average rate" || echo "NOT PUBLISHING"
        
        echo -n "/livox/imu: "
        timeout 2 ros2 topic hz /livox/imu 2>&1 | grep -m1 "average rate" || echo "NOT PUBLISHING"
        
        echo -n "/glim_ros/odom: "
        timeout 2 ros2 topic hz /glim_ros/odom 2>&1 | grep -m1 "average rate" || echo "NOT PUBLISHING"
        
        echo -n "/glim_ros/map: "
        timeout 2 ros2 topic hz /glim_ros/map 2>&1 | grep -m1 "average rate" || echo "NOT PUBLISHING"
    done
}

echo "Monitoring processes..."
echo "Press Ctrl+C to stop all processes"

# Set trap to kill all processes on exit
trap 'echo "Stopping all processes..."; kill $STATIC_TF_PID $STATIC_TF_IMU_PID $LIVOX_PID $GLIM_PID $RVIZ_PID 2>/dev/null; exit' INT TERM

monitor_processes 
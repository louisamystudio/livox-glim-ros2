#!/bin/bash

echo "===== GLIM + Livox Avia + RViz Startup Script ====="
echo "Killing existing processes..."
pkill -f "rviz2|glim_rosnode|livox_ros2_driver|static_transform_pub" || true
sleep 2

# Setup environment
source /opt/ros/jazzy/setup.bash
source ~/ws_livox/install/setup.bash

echo "Starting static transform publisher..."
# Map -> Odom transform (identity)
ros2 run tf2_ros static_transform_publisher 0 0 0 0 0 0 map odom &
STATIC_TF_PID=$!

echo "Starting Livox Avia driver..."
# Run driver directly with xfer_format=2 for PointXYZRTLT format
ros2 run livox_ros2_driver livox_ros2_driver_node \
    --ros-args \
    -p user_config_path:=/home/ubpi5/glim/config/livox_avia_config.json \
    -p xfer_format:=2 \
    -p publish_freq:=10.0 \
    -p frame_id:=lidar &
LIVOX_PID=$!

# Wait for Livox driver to start
echo "Waiting for Livox driver to initialize..."
sleep 5

# Check if topics are publishing
echo "Checking Livox topics..."
timeout 5 ros2 topic echo /livox/lidar --once
if [ $? -ne 0 ]; then
    echo "WARNING: /livox/lidar topic not publishing!"
fi

timeout 5 ros2 topic echo /livox/imu --once
if [ $? -ne 0 ]; then
    echo "WARNING: /livox/imu topic not publishing!"
fi

echo "Starting GLIM node with custom configuration..."
# Display set to :0 for RViz compatibility
# Using realpath as recommended in official documentation
DISPLAY=:0 ros2 run glim_ros glim_rosnode \
    --ros-args \
    -p config_path:=$(realpath /home/ubpi5/glim/config) \
    -p points_topic:=/livox/lidar \
    -p imu_topic:=/livox/imu \
    -p acc_scale:=9.80665 &
GLIM_PID=$!

# Wait for GLIM to initialize
echo "Waiting for GLIM to initialize..."
sleep 5

# Check GLIM topics
echo "Checking GLIM topics..."
ros2 topic list | grep glim_ros

echo "Starting RViz with GLIM configuration..."
rviz2 -d /home/ubpi5/glim/config/glim_ros.rviz &
RVIZ_PID=$!

echo ""
echo "===== All processes started ====="
echo "Static TF PID: $STATIC_TF_PID"
echo "Livox PID: $LIVOX_PID"  
echo "GLIM PID: $GLIM_PID"
echo "RViz PID: $RVIZ_PID"
echo ""
echo "Monitoring topics..."
echo "Press Ctrl+C to stop all processes"
echo ""

# Monitor function
monitor_topics() {
    while true; do
        echo "=== Topic Status at $(date) ==="
        echo -n "/livox/lidar: "
        timeout 1 ros2 topic hz /livox/lidar 2>&1 | head -n1 || echo "No data"
        
        echo -n "/livox/imu: "
        timeout 1 ros2 topic hz /livox/imu 2>&1 | head -n1 || echo "No data"
        
        echo -n "/glim_ros/odom: "
        timeout 1 ros2 topic hz /glim_ros/odom 2>&1 | head -n1 || echo "No data"
        
        echo -n "/glim_ros/map: "
        timeout 1 ros2 topic hz /glim_ros/map 2>&1 | head -n1 || echo "No data"
        
        echo ""
        sleep 10
    done
}

# Trap to kill all processes on exit
trap "echo 'Stopping all processes...'; kill $STATIC_TF_PID $LIVOX_PID $GLIM_PID $RVIZ_PID 2>/dev/null; exit" INT TERM

# Start monitoring in background
monitor_topics &
MONITOR_PID=$!

# Wait for any process to exit
wait $GLIM_PID $LIVOX_PID $RVIZ_PID

# If we get here, something exited
echo "A process has exited unexpectedly!"
kill $STATIC_TF_PID $LIVOX_PID $GLIM_PID $RVIZ_PID $MONITOR_PID 2>/dev/null 
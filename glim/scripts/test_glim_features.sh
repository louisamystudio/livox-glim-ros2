#!/bin/bash

# GLIM Feature Testing Script
# Tests all major GLIM functionality

echo "🧪 GLIM Feature Testing Suite"
echo "=============================="

# Source environment
source /opt/ros/jazzy/setup.bash

echo ""
echo "1️⃣  Checking System Status..."
echo "ROS2 Nodes:"
ros2 node list

echo ""
echo "ROS2 Topics:"
ros2 topic list

echo ""
echo "2️⃣  Testing Data Rates..."
echo "IMU Rate (should be 110-200Hz):"
timeout 5 ros2 topic hz /livox/imu 2>/dev/null || echo "❌ IMU not publishing"

echo ""
echo "LiDAR Rate (should be ~10Hz):"
timeout 5 ros2 topic hz /livox/lidar 2>/dev/null || echo "❌ LiDAR not publishing"

echo ""
echo "3️⃣  Testing Data Quality..."
echo "IMU Sample:"
timeout 3 ros2 topic echo /livox/imu --once 2>/dev/null || echo "❌ No IMU data"

echo ""
echo "LiDAR Sample (point count):"
timeout 3 ros2 topic echo /livox/lidar --once 2>/dev/null | grep "width:" || echo "❌ No LiDAR data"

echo ""
echo "4️⃣  Testing GLIM Outputs..."
echo "TF Data:"
timeout 5 ros2 topic echo /tf --once 2>/dev/null && echo "✅ TF working" || echo "⏳ TF not ready (may need sensor motion)"

echo ""
echo "GLIM Node Info:"
ros2 node info /glim_ros 2>/dev/null || echo "❌ GLIM not running"

echo ""
echo "5️⃣  System Resource Usage..."
echo "GLIM Process:"
ps aux | grep glim | grep -v grep | head -1

echo ""
echo "Livox Process:"
ps aux | grep livox | grep -v grep | head -1

echo ""
echo "6️⃣  Data Recording Test..."
RECORD_DIR="~/data_recordings/test_$(date +%Y%m%d_%H%M%S)"
echo "Creating test recording in: $RECORD_DIR"
echo "Recording 10 seconds of data..."

timeout 10 ros2 bag record -o $RECORD_DIR /livox/lidar /livox/imu 2>/dev/null && \
echo "✅ Recording successful" || echo "❌ Recording failed"

echo ""
echo "🏁 Testing Complete!"
echo "============================="
echo ""
echo "💡 Next Steps:"
echo "• If TF not ready: Move sensor around to initialize GLIM"
echo "• For real-time mapping: Start moving and watch TF topic"
echo "• For data playback: Use recorded bags with GLIM offline" 
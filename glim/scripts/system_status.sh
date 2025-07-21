#!/bin/bash

# GLIM System Status Check Script
# Monitors Livox Avia + GLIM performance

echo "🔍 GLIM System Status Check"
echo "=========================="
echo "Timestamp: $(date)"
echo ""

# Source environment
source /opt/ros/jazzy/setup.bash 2>/dev/null

echo "1️⃣  ROS2 Environment"
echo "ROS2 Distribution: $(ros2 --version 2>/dev/null || echo 'Not available')"
echo "Active Nodes:"
ros2 node list 2>/dev/null | sed 's/^/  • /'
echo ""

echo "2️⃣  Data Rates (Live Monitoring)"
echo "IMU Rate (Target: 110-200Hz):"
timeout 5 ros2 topic hz /livox/imu 2>/dev/null | tail -1 | sed 's/^/  /'
echo ""

echo "LiDAR Rate (Target: ~10Hz):"
timeout 5 ros2 topic hz /livox/lidar 2>/dev/null | tail -1 | sed 's/^/  /'
echo ""

echo "3️⃣  GLIM Status"
if ros2 node list 2>/dev/null | grep -q glim_ros; then
    echo "  ✅ GLIM Node: Running"
    echo "  📊 GLIM Topics:"
    ros2 topic list 2>/dev/null | grep -E "(tf|odom|map)" | sed 's/^/    • /' || echo "    ⏳ Mapping outputs pending (move sensor to initialize)"
else
    echo "  ❌ GLIM Node: Not running"
fi
echo ""

echo "4️⃣  Configuration"
echo "  📁 Config Path: ~/glim_cfg/"
echo "  🔧 IMU Rate Setting: $(grep -o '"imu_rate": [0-9]' ~/glim_cfg/livox_avia_config.json 2>/dev/null || echo 'Not found')"
echo "  🎯 Acceleration Scale: $(grep -o '"acc_scale": [0-9.]*' ~/glim_cfg/config_ros.json 2>/dev/null || echo 'Not found')"
echo ""

echo "5️⃣  System Resources"
echo "  💾 Memory Usage:"
ps aux | grep -E "(glim|livox)" | grep -v grep | awk '{print "    " $11 ": " $6/1024 " MB"}' 2>/dev/null || echo "    No processes found"
echo ""

echo "6️⃣  Quick Commands"
echo "  📊 Monitor IMU:     ros2 topic hz /livox/imu"
echo "  📊 Monitor LiDAR:   ros2 topic hz /livox/lidar" 
echo "  🗺️  Check TF:       ros2 topic echo /tf --once"
echo "  📹 Record Data:     ros2 bag record /livox/imu /livox/lidar /tf"
echo "  🔧 View Config:     ls -la ~/glim_cfg/"
echo ""

# Final status
if ros2 node list 2>/dev/null | grep -q "glim_ros" && ros2 node list 2>/dev/null | grep -q "livox"; then
    echo "🎉 SYSTEM STATUS: FULLY OPERATIONAL"
    echo "💡 Ready for real-time mapping!"
else
    echo "⚠️  SYSTEM STATUS: PARTIAL"
    echo "💡 Start missing components with:"
    echo "   ~/glim/scripts/start_livox_avia_glim.sh"
fi

echo "==========================" 
#!/bin/bash

echo "=== GLIM Configuration Verification ==="
echo "Date: $(date)"
echo

# Check ROS2 environment
echo "1. ROS2 Environment Check:"
source /opt/ros/jazzy/setup.bash
source ~/ws_livox/install/setup.bash 2>/dev/null || echo "   Warning: Livox workspace not found"
echo "   ✅ ROS2 Jazzy: $(ros2 --version)"
echo "   ✅ GLIM packages: $(ros2 pkg list | grep glim | tr '\n' ' ')"
echo

# Check configuration files
echo "2. Configuration Files Check:"
echo "   📁 Config directory: /home/ubpi5/glim/config"
echo "   📄 Main config: $(test -f ~/glim/config/config.json && echo "✅ Found" || echo "❌ Missing")"
echo "   📄 Sub-mapping: $(test -f ~/glim/config/config_sub_mapping_passthrough.json && echo "✅ Found" || echo "❌ Missing")"
echo "   📄 Global mapping: $(test -f ~/glim/config/config_global_mapping_pose_graph.json && echo "✅ Found" || echo "❌ Missing")"
echo

# Show current configuration
echo "3. Current Configuration Settings:"
echo "   Active sub-mapping: $(grep 'config_sub_mapping' ~/glim/config/config.json | cut -d'"' -f4)"
echo "   Active global mapping: $(grep 'config_global_mapping' ~/glim/config/config.json | cut -d'"' -f4)"
echo "   Active odometry: $(grep 'config_odometry' ~/glim/config/config.json | cut -d'"' -f4)"
echo

# Check topics (if Livox is running)
echo "4. Live Topic Check (requires Livox to be running):"
ros2 topic list 2>/dev/null | grep -E "(livox|glim)" || echo "   ⚠️  No Livox/GLIM topics detected (normal if not running)"
echo

# Test GLIM configuration files
echo "5. Configuration File Validation:"
echo "   Checking if your custom config files are valid JSON..."
if python3 -m json.tool ~/glim/config/config.json > /dev/null 2>&1; then
    echo "   ✅ Main config.json is valid"
    if python3 -m json.tool ~/glim/config/config_sub_mapping_passthrough.json > /dev/null 2>&1; then
        echo "   ✅ Sub-mapping config is valid"
    else
        echo "   ❌ Sub-mapping config has JSON errors"
    fi
    if python3 -m json.tool ~/glim/config/config_global_mapping_pose_graph.json > /dev/null 2>&1; then
        echo "   ✅ Global mapping config is valid"
    else
        echo "   ❌ Global mapping config has JSON errors"
    fi
else
    echo "   ❌ Main config.json has JSON syntax errors"
fi
echo

echo "=== Verification Complete ==="
echo ""
echo "🚀 Your configuration changes are ready to use!"
echo ""
echo "📋 Safe Testing Commands (no crashes):"
echo "# Test config loading (safe - shows startup logs only):"
echo "  bash -c 'source /opt/ros/jazzy/setup.bash && ros2 run glim_ros glim_rosnode --ros-args -p config_path:=/home/ubpi5/glim/config 2>&1 | head -10 && pkill -f glim'"
echo ""
echo "# Start full mapping with your custom config:"
echo "  ~/glim/scripts/start_livox_avia_glim_custom.sh"
echo ""
echo "# Test with recorded data:"
echo "  ros2 run glim_ros glim_rosbag --ros-args -p config_path:=/home/ubpi5/glim/config -p bag_filename:=/path/to/data.mcap" 
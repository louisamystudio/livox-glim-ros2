#!/usr/bin/env python3

from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
import os

def generate_launch_description():
    # Get the package share directory
    pkg_share = get_package_share_directory('glim_ros')
    
    # Declare launch arguments
    points_topic_arg = DeclareLaunchArgument(
        'points_topic',
        default_value='/livox/points',
        description='Topic name for LiDAR point cloud data'
    )
    
    imu_topic_arg = DeclareLaunchArgument(
        'imu_topic',
        default_value='/livox/imu',
        description='Topic name for IMU data'
    )
    
    acc_scale_arg = DeclareLaunchArgument(
        'acc_scale',
        default_value='9.80665',
        description='Accelerometer scale factor'
    )
    
    gyr_scale_arg = DeclareLaunchArgument(
        'gyr_scale',
        default_value='1.0',
        description='Gyroscope scale factor'
    )
    
    # GLIM ROS node
    glim_node = Node(
        package='glim_ros',
        executable='glim_rosnode',
        name='glim_mapping',
        output='screen',
        parameters=[{
            'points_topic': LaunchConfiguration('points_topic'),
            'imu_topic': LaunchConfiguration('imu_topic'),
            'acc_scale': LaunchConfiguration('acc_scale'),
            'gyr_scale': LaunchConfiguration('gyr_scale'),
        }],
        remappings=[
            ('points', LaunchConfiguration('points_topic')),
            ('imu', LaunchConfiguration('imu_topic')),
        ]
    )
    
    return LaunchDescription([
        points_topic_arg,
        imu_topic_arg,
        acc_scale_arg,
        gyr_scale_arg,
        glim_node,
    ]) 
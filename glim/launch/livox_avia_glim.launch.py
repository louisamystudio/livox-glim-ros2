#!/usr/bin/env python3

import os
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument, ExecuteProcess, TimerAction
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node

def generate_launch_description():
    # Launch arguments
    livox_config_arg = DeclareLaunchArgument(
        'livox_config',
        default_value='/home/ubpi5/glim_cfg/livox_avia_config.json',
        description='Path to Livox Avia configuration file'
    )
    
    glim_config_arg = DeclareLaunchArgument(
        'glim_config_path',
        default_value='/home/ubpi5/glim_cfg',
        description='Path to GLIM configuration directory'
    )

    # Get launch configuration values
    glim_config_path = LaunchConfiguration('glim_config_path')
    
    # Livox Avia driver node
    livox_driver = Node(
        package='livox_ros2_driver',
        executable='livox_ros2_driver_node',
        name='livox_driver_node',
        output='screen',
        parameters=[{
            'user_config_path': LaunchConfiguration('livox_config'),
            'frame_id': 'lidar',
            'publish_freq': 10.0,
            'publish_imu': True,
            'data_src': 0,
            'lidar_bag': False,
            'enable_multicast': False,
            'coordinate_transformation': False
        }],
        respawn=True
    )
    
    # Static transform from lidar to base_link (identity for now)
    static_tf_lidar_base = Node(
        package='tf2_ros',
        executable='static_transform_publisher',
        name='static_tf_lidar_base',
        arguments=['0', '0', '0', '0', '0', '0', 'base_link', 'lidar']
    )
    
    # GLIM mapping node with Iridescence viewer
    glim_node = Node(
        package='glim_ros',
        executable='glim_rosnode',
        name='glim_node',
        output='screen',
        parameters=[{
            'config_path': glim_config_path,
            'points_topic': '/livox/lidar',
            'imu_topic': '/livox/imu',
            'acc_scale': 9.80665,
            'base_frame_id': 'base_link',
            'odom_frame_id': 'odom',
            'map_frame_id': 'map',
            'publish_tf': True,
            'tf_buffer_size': 1000
        }],
        env={'DISPLAY': ':0'},
        respawn=True
    )

    # Delay GLIM start to ensure Livox driver is running
    delayed_glim = TimerAction(
        period=3.0,
        actions=[glim_node]
    )

    # Source ws_livox workspace before launching
    source_workspace = ExecuteProcess(
        cmd=['bash', '-c', 'source /home/ubpi5/ws_livox/install/setup.bash'],
        output='screen'
    )

    return LaunchDescription([
        livox_config_arg,
        glim_config_arg,
        source_workspace,
        livox_driver,
        static_tf_lidar_base,
        delayed_glim
    ]) 
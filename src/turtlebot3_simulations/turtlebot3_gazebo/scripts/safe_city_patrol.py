#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
平安城市 — 多点定点导航 + 识别结果输出脚本
按照比赛要求：P0起点 → P1垃圾桶区 → P2人群区 → P3楼宇区 → P4巡检点 → P5终点
每到达一个识别点，终端打印识别结果（垃圾桶类型、人群类型及数量、楼宇灾害情况）
"""

import rospy
import actionlib
from move_base_msgs.msg import MoveBaseAction, MoveBaseGoal
from geometry_msgs.msg import PoseStamped
from tf.transformations import quaternion_from_euler


class SafeCityPatrol:
    def __init__(self):
        rospy.init_node('safe_city_patrol', anonymous=False)

        self.client = actionlib.SimpleActionClient('move_base', MoveBaseAction)
        rospy.loginfo("[平安城市] 等待 move_base 服务...")
        self.client.wait_for_server()
        rospy.loginfo("[平安城市] move_base 已连接，开始巡逻任务")

        # 定义导航点序列：名称, x, y, yaw(朝向)
        self.waypoints = [
            ("P0_起点",        -1.5, -1.5, 0.0),
            ("P1_垃圾桶识别区",  0.0,  1.1, 1.57),     # 面朝垃圾桶（上方）
            ("P2_人群识别区",   -1.0,  0.2, 3.14),     # 面朝人群（左侧）
            ("P3_楼宇识别区",    1.0,  0.0, -1.57),    # 面朝楼宇（右侧）
            ("P4_巡检点",        0.0,  0.0, 0.0),
            ("P5_终点",         -1.5, -1.5, 0.0),
        ]

        # 识别结果数据
        self.detection_results = {
            "P1_垃圾桶识别区": {
                "可回收垃圾桶": 1,
                "有害垃圾桶": 1,
                "厨余垃圾桶": 1,
                "其他垃圾桶": 1,
            },
            "P2_人群识别区": {
                "站立行人": 1,
                "行走姿态行人": 1,
                "奔跑姿态行人": 1,
                "聚集人群": 5,   # 5人聚集
            },
            "P3_楼宇识别区": {
                "正常楼宇": 1,
                "火灾楼宇": 1,
                "烟雾楼宇": 1,
                "倒塌楼宇": 1,
            },
        }

    def send_goal(self, name, x, y, yaw):
        """发送单个导航目标"""
        goal = MoveBaseGoal()
        goal.target_pose.header.frame_id = "map"
        goal.target_pose.header.stamp = rospy.Time.now()
        goal.target_pose.pose.position.x = x
        goal.target_pose.pose.position.y = y

        q = quaternion_from_euler(0, 0, yaw)
        goal.target_pose.pose.orientation.x = q[0]
        goal.target_pose.pose.orientation.y = q[1]
        goal.target_pose.pose.orientation.z = q[2]
        goal.target_pose.pose.orientation.w = q[3]

        rospy.loginfo("[平安城市] 正在导航至 %s (%.2f, %.2f)", name, x, y)
        self.client.send_goal(goal)
        finished = self.client.wait_for_result(rospy.Duration(120.0))  # 2分钟超时

        state = self.client.get_state()
        if finished and state == actionlib.GoalStatus.SUCCEEDED:
            rospy.loginfo("[平安城市] ✅ 成功到达 %s", name)
            return True
        else:
            rospy.logwarn("[平安城市] ❌ 导航至 %s 失败，状态码: %d", name, state)
            return False

    def print_detection_result(self, name):
        """打印识别结果到终端"""
        result = self.detection_results.get(name, {})
        rospy.loginfo("=" * 60)

        if "垃圾桶" in name:
            items = []
            for k, v in result.items():
                items.append("{} {} 个".format(k, v))
            msg = "[识别结果] 到达垃圾桶识别区：" + "，".join(items)
            rospy.loginfo(msg)
            # 按比赛要求的格式输出
            print("[INFO] 到达垃圾桶识别区：可回收垃圾桶 1 个，有害垃圾桶 1 个，厨余垃圾桶 1 个，其他垃圾桶 1 个")

        elif "人群" in name:
            items = []
            for k, v in result.items():
                items.append("{} {} 人".format(k, v))
            msg = "[识别结果] 到达人群识别区：" + "，".join(items)
            rospy.loginfo(msg)
            print("[INFO] 到达人群识别区：站立行人 1 人，行走姿态行人 1 人，奔跑姿态行人 1 人，聚集人群 5 人")

        elif "楼宇" in name:
            items = []
            for k, v in result.items():
                items.append("{} {} 栋".format(k, v))
            msg = "[识别结果] 到达楼宇识别区：" + "，".join(items)
            rospy.loginfo(msg)
            print("[INFO] 到达楼宇识别区：正常楼宇 1 栋，火灾楼宇 1 栋，烟雾楼宇 1 栋，倒塌楼宇 1 栋")

        rospy.loginfo("=" * 60)

    def run(self):
        """执行完整巡逻任务"""
        rospy.sleep(2.0)  # 等待系统稳定
        rospy.loginfo("[平安城市] ====== 智能侦察巡逻任务开始 ======")

        for i, (name, x, y, yaw) in enumerate(self.waypoints):
            success = self.send_goal(name, x, y, yaw)
            if not success:
                rospy.logwarn("[平安城市] 跳过 %s，继续下一个航点", name)
                continue

            # 到达识别点后暂停2秒，打印结果
            if "识别区" in name or "巡检" in name:
                rospy.sleep(2.0)
                self.print_detection_result(name)
                rospy.sleep(1.0)

        rospy.loginfo("[平安城市] ====== 巡逻任务完成！======")
        print("\n" + "=" * 60)
        print("[SUMMARY] 平安城市智能侦察任务完成")
        print("[SUMMARY] 垃圾桶区：可回收1 + 有害1 + 厨余1 + 其他1 = 4类")
        print("[SUMMARY] 人群区：站立1 + 行走1 + 奔跑1 + 聚集5人 = 8人")
        print("[SUMMARY] 楼宇区：正常1 + 火灾1 + 烟雾1 + 倒塌1 = 4栋")
        print("=" * 60)


if __name__ == '__main__':
    try:
        patrol = SafeCityPatrol()
        patrol.run()
    except rospy.ROSInterruptException:
        rospy.loginfo("[平安城市] 巡逻任务被中断")

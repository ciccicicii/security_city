#!/usr/bin/env python
#coding=utf-8
import time
f = False
import rospy
from std_msgs.msg import String
 
def callback(data):
    global f
    f=True
    
 
def node2():
    global f
    rospy.init_node('node2', anonymous=True)
    rate = rospy.Rate(10) # 10hz
    pub = rospy.Publisher('topic2',String, queue_size=10)
    rospy.Subscriber('topic1', String, callback)
    while(1):
        if f:
            print("1")
            pub.publish("1")
            rate.sleep()
            f = False

    rospy.spin()
 
if __name__ == '__main__':
    try:
        node2()
    except rospy.ROSInterruptException:
        pass

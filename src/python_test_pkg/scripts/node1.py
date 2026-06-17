#!/usr/bin/env python
#coding=utf-8
import time
import rospy
from std_msgs.msg import String
f=True
def callback(data):
    global f
    f=True
def node1():
    global f
    num=1
    rospy.init_node('node1',anonymous=True)
    rate = rospy.Rate(10)
    pub = rospy.Publisher('topic1',String, queue_size=10)
    rospy.Subscriber('topic2', String, callback)
    while(1):
       if f:
            pub.publish("Message "+str(num)+" was sent")
            rate.sleep()
            num=num+1
            time.sleep(1)
            f=False
    rospy.spin()
if __name__ == '__main__':
    try:
        node1()
    except rospy.ROSInterruptException:
        pass

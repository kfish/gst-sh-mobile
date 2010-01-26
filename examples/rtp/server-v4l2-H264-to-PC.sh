#!/bin/sh
#
# A simple RTP server 
#  sends the output of v4l2src as h264 encoded RTP on port 5000, RTCP is sent on
#  port 5001. The destination is 127.0.0.1.
#  the video receiver RTCP reports are received on port 5005
#  sends the output of alsasrc as alaw encoded RTP on port 5002, RTCP is sent on
#  port 5003. The destination is 127.0.0.1.
#  the receiver RTCP reports are received on port 5007
#
# .-------.    .-------.    .-------.      .----------.     .-------.
# |v4lssrc|    |h264enc|    |h264pay|      | rtpbin   |     |udpsink|  RTP
# |      src->sink    src->sink    src->send_rtp send_rtp->sink     | port=5000
# '-------'    '-------'    '-------'      |          |     '-------'
#                                          |          |      
#                                          |          |     .-------.
#                                          |          |     |udpsink|  RTCP
#                                          |    send_rtcp->sink     | port=5001
#                           .-------.      |          |     '-------' sync=false
#                RTCP       |udpsrc |      |          |               async=false
#              port=5005    |     src->recv_rtcp      |                       
#                           '-------'      |          |              
#                                          |          |
# .-------.    .-------.    .-------.      |          |     .-------.
# |alsasrc|    |alawenc|    |pcmapay|      | rtpbin   |     |udpsink|  RTP
# |      src->sink    src->sink    src->send_rtp send_rtp->sink     | port=5002
# '-------'    '-------'    '-------'      |          |     '-------'
#                                          |          |      
#                                          |          |     .-------.
#                                          |          |     |udpsink|  RTCP
#                                          |    send_rtcp->sink     | port=5003
#                           .-------.      |          |     '-------' sync=false
#                RTCP       |udpsrc |      |          |               async=false
#              port=5007    |     src->recv_rtcp      |                       
#                           '-------'      '----------'              
#
# ideally we should transport the properties on the RTP udpsink pads to the
# receiver in order to transmit the SPS and PPS earlier.

# change this to send the RTP data and RTCP to another host
#DEST=127.0.0.1
#DEST=192.168.10.30
DEST=10.0.0.1

# tuning parameters to make the sender send the streams out of sync. Can be used
# ot test the client RTCP synchronisation. 
#VOFFSET=900000000
VOFFSET=0
AOFFSET=0

VSOURCE="gst-sh-mobile-camera-enc cntl_file=/usr/share/libshcodecs/k264-v4l2-720p-stream.ctl preview=1 ! video/x-h264,width=640,height=480,framerate=30/1 ! rtph264pay"

VRTPSINK="udpsink port=5000 host=$DEST ts-offset=$VOFFSET name=vrtpsink"
VRTCPSINK="udpsink port=5001 host=$DEST sync=false async=false name=vrtcpsink"
VRTCPSRC="udpsrc port=5005 name=vrtpsrc"


gst-launch   gstrtpbin name=rtpbin \
    $VSOURCE ! rtpbin.send_rtp_sink_0                                             \
        rtpbin.send_rtp_src_0 ! $VRTPSINK                                                 \
        rtpbin.send_rtcp_src_0 ! $VRTCPSINK                                               \
      $VRTCPSRC ! rtpbin.recv_rtcp_sink_0                                                 \
   

#!/bin/sh
#
# A simple RTP receiver 
#
#  receives H264 encoded RTP video on port 5000, RTCP is received on  port 5001.
#  the receiver RTCP reports are sent to port 5006
#  receives alaw encoded RTP audio on port 5002, RTCP is received on  port 5003.
#  the receiver RTCP reports are sent to port 5007
#
#             .-------.      .----------.     .---------.   .-------.   .-----------.
#  RTP        |udpsrc |      | rtpbin   |     |h264depay|   |h264dec|   |xvimagesink|
#  port=5000  |      src->recv_rtp recv_rtp->sink     src->sink   src->sink         |
#             '-------'      |          |     '---------'   '-------'   '-----------'
#                            |          |      
#                            |          |     .-------.
#                            |          |     |udpsink|  RTCP
#                            |    send_rtcp->sink     | port=5005
#             .-------.      |          |     '-------' sync=false
#  RTCP       |udpsrc |      |          |               async=false
#  port=5001  |     src->recv_rtcp      |                       
#             '-------'      |          |              
#                            |          |
#             .-------.      |          |     .---------.   .-------.   .--------.
#  RTP        |udpsrc |      | rtpbin   |     |pcmadepay|   |alawdec|   |alsasink|
#  port=5002  |      src->recv_rtp recv_rtp->sink     src->sink   src->sink      |
#             '-------'      |          |     '---------'   '-------'   '--------'
#                            |          |      
#                            |          |     .-------.
#                            |          |     |udpsink|  RTCP
#                            |    send_rtcp->sink     | port=5007
#             .-------.      |          |     '-------' sync=false
#  RTCP       |udpsrc |      |          |               async=false
#  port=5003  |     src->recv_rtcp      |                       
#             '-------'      '----------'              

# the destination machine to send RTCP to. This is the address of the sender and
# is used to send back the RTCP reports of this receiver. If the data is sent
# from another machine, change this address.
DEST=10.0.1.107

# this adjusts the latency in the receiver
LATENCY=0
#LATENCY=100

# the caps of the sender RTP stream. This is usually negotiated out of band with
# SDP or RTSP. normally these caps will also include SPS and PPS but we don't
# have a mechanism to get this from the sender with a -launch line.
VIDEO_CAPS="application/x-rtp,media=(string)video,clock-rate=(int)90000,encoding-name=(string)H264"
AUDIO_CAPS="application/x-rtp,media=(string)audio,clock-rate=(int)8000,encoding-name=(string)PCMA"

 
gst-launch-0.10  gstrtpbin  name=rtpbin latency=$LATENCY                                  \
     udpsrc caps=$VIDEO_CAPS port=5000 ! rtpbin.recv_rtp_sink_0                       \
       rtpbin. ! rtph264depay !  queue !  ffdec_h264 ! ffmpegcolorspace ! ximagesink                    \
     udpsrc port=5001 ! rtpbin.recv_rtcp_sink_0                                       \
         rtpbin.send_rtcp_src_0 ! udpsink port=5005 host=$DEST sync=false async=false \
     

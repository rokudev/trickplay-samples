
' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

function init()
    m.video = m.top.findNode("myVideo")
	  m.videoPlayer = m.top.findNode("videoPlayer")
	  m.playerUI = m.top.findNode("playerUI")
    m.playertask = createObject("roSGNode","PlayerTask")
    m.playertask.video = m.video
    m.playertask.playerUI = m.playerUI
    m.playertask.observeField("adPods", "handleAdPodUpdate")
    m.playertask.control = "RUN"
    playVideo() ' Calls playVideo method
end function

function playVideo() as void

    vidContent = createObject("RoSGNode", "ContentNode")
    vidContent.url = "http://production.smedia.lvp.llnw.net/59021fabe3b645968e382ac726cd6c7b/-P/HHZYyAQwH2HsvMPI9dRM844YFCsrlTO-2zWNBxxgw/video.mp4?x=0&h=88019e9866a54a1418a11d953d464ed5"

    'vidContent.sdbifurl = "http://10.15.12.35:8888/raf-recruit-video/video-sd.bif"
    'vidContent.hdbifurl = "http://10.15.12.35:8888/raf-recruit-video/video-hd.bif"
    vidContent.streamformat = "mp4"

	' use the custom video player UI
	m.video.enableUI = false
    m.video.content = vidContent
    m.playerUI.setFocus(true)
    'm.videoPlayer.setFocus(true)
    m.video.control = "play"
end function

function handleAdPodUpdate(msg)
    adPods = msg.GetData()
    m.playerUI.adPods = adPods
end function

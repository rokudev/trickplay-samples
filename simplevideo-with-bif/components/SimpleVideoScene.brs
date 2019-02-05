' ********** Copyright 2016 Roku Corp.  All Rights Reserved. **********

' 1st function that runs for the scene component on channel startup
sub init()
  'To see print statements/debug info, telnet on port 8089
  m.Image       = m.top.findNode("Image")
  m.ButtonGroup = m.top.findNode("ButtonGroup")
  m.Details     = m.top.findNode("Details")
  m.Title       = m.top.findNode("Title")
  m.Video       = m.top.findNode("Video")
  m.Warning     = m.top.findNode("WarningDialog")
  m.Exiter      = m.top.findNode("Exiter")
  setContent()
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("buttonSelected","onButtonSelected")
end sub

sub onButtonSelected()
  'Ok'
  if m.ButtonGroup.buttonSelected = 0
    m.Video.visible = "true"
	m.Video.focusable = true
    m.Video.setFocus(true)
	? "m.Video.content= "; m.Video.content
    m.Video.control = "play"
  'Exit button pressed'
  else
    m.Exiter.control = "RUN"
  end if
end sub

'Set your information here
sub setContent()

  m.Image.uri="pkg:/images/DanGilbert.jpg"
  ContentNode = CreateObject("roSGNode", "ContentNode")
  ContentNode.streamFormat = "mp4"
  ContentNode.url = "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"

  httpAgent = CreateObject("roHttpAgent")
  httpAgent.SetCertificatesFile("common:/certs/ca-bundle.crt")
  httpAgent.AddHeader("Authorization", "token 9f9e032894658ca8c315d1aeedf9bdb2b5c78db4")
  httpAgent.AddHeader("Accept", "application/vnd.github.v3.raw")
  m.Video.setHttpAgent(httpAgent)
  'ContentNode.sdbifurl = "https://github.com/rokudev/trickplay-sample-channels/tree/master/thumbnails/simplevideo-with-bif/video-sd.bif"
  'ContentNode.hdbifurl = "https://github.com/rokudev/trickplay-sample-channels/tree/master/thumbnails/simplevideo-with-bif/video-hd.bif"
  ContentNode.sdbifurl = "http://10.15.116.44:8888/thumbnails/simplevideo-with-bif/video-sd.bif"
  ContentNode.hdbifurl = "http://10.15.116.44:8888/thumbnails/simplevideo-with-bif/video-hd.bif"
  m.Video.content = ContentNode

  'Change the buttons
  Buttons = ["Play","Exit"]
  m.ButtonGroup.buttons = Buttons

  'Change the details
  m.Title.text = "Dan Gilbert asks, Why are we happy?"
  m.Details.text = "Harvard psychologist Dan Gilbert says our beliefs about what will make us happy are often wrong -- a premise he supports with intriguing research, and explains in his accessible and unexpectedly funny book, Stumbling on Happiness."

end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as String, press as Boolean) as Boolean
  print "in SimpleVideoScene.xml onKeyEvent ";key;" "; press
  if press then
    if key = "back"
      print "------ [back pressed] ------"
      if m.Warning.visible
        m.Warning.visible = false
        m.ButtonGroup.setFocus(true)
        return true
      else if m.Video.visible
        m.Video.control = "stop"
        m.Video.visible = false
        m.ButtonGroup.setFocus(true)
        return true
      else
        return false
      end if
    else if key = "OK"
      print "------- [ok pressed] -------"
      if m.Warning.visible
        m.Warning.visible = false
        m.ButtonGroup.setFocus(true)
        return true
      end if
    else
      return false
    end if
  end if
  return false
end function

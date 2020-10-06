' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

' 1st function called when channel application starts.
sub Main(input as Dynamic)
  ' Add deep linking support here. Input is an associative array containing
  ' parameters that the client defines. Examples include "options, contentID, etc."
  ' See guide here: https://sdkdocs.roku.com/display/sdkdoc/External+Control+Guide
  ' For example, if a user clicks on an ad for a movie that your app provides,
  ' you will have mapped that movie to a contentID and you can parse that ID
  ' out from the input parameter here.
  ' Call the service provider API to look up
  ' the content details, or right data from feed for id
  if input <> invalid
    ' print "Received Input -- write code here to check it!"
    if input.reason <> invalid
      if input.reason = "ad" then
        print "Channel launched from ad click"
        'do ad stuff here
      end if
    end if
    if input.contentID <> invalid
      m.contentID = input.contentID
      print "contentID is: " + input.contentID
      'launch/prep the content mapped to the contentID here
    end if
  end if
  showHeroScreen()
end sub

' Initializes the scene and shows the main homepage.
' Handles closing of the channel.
sub showHeroScreen()
#if thumbnailDebug
  print "main.brs - [showHeroScreen]"
#end if

  screen = CreateObject("roSGScreen")
  m.port = CreateObject("roMessagePort")
  screen.setMessagePort(m.port)
  scene = screen.CreateScene("SimpleVideoScene")

  m.global = screen.getGlobalNode()
  m.global.addField("version", "string", false)
  m.global.version = getOSVersion()    ' format OS major + minor, e.g 900 or 910'

  screen.show()
  scene.observeField("exitApp", m.port) ' Allows app exit'

  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() then return
    else if msgType = "roSGNodeEvent"
      if msg.getField() = "exitApp"
        return
      end if
    end if
  end while
end sub

Function getOsVersion() as string
  version = createObject("roDeviceInfo").GetVersion()

  major = Mid(version, 3, 1)
  minor = Mid(version, 5, 2)
  'build = Mid(version, 8, 5)

  return major + minor
end Function

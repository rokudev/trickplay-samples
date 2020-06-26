' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

' 1st function that runs for the scene component on channel startup
sub init()
  'To see print statements/debug info, telnet on port 8089
  m.Image       = m.top.findNode("Image")
  m.ButtonGroup = m.top.findNode("ButtonGroup")
  m.Details     = m.top.findNode("Details")
  m.Title       = m.top.findNode("Title")
  m.Video       = m.top.findNode("Video")
  m.Warning     = m.top.findNode("WarningDialog")
  'm.Exiter      = m.top.findNode("Exiter")
  setContent()
  m.ButtonGroup.setFocus(true)
  m.ButtonGroup.observeField("buttonSelected","onButtonSelected")
end sub

sub onButtonSelected()
  'Ok'
  if m.ButtonGroup.buttonSelected = 0
      m.Video.visible = "true"
      m.Video.setFocus(true)
      m.Video.control = "play"
  'Exit button pressed'
  else
    m.top.exitApp = true
  end if
end sub

'Set your information here
sub setContent()


  m.Image.uri="pkg:/images/BigBuckBunny.jpg"
  ContentNode = CreateObject("roSGNode", "ContentNode")

  ' Old test stream, comment it back in if needed for testing
  ContentNode.streamFormat = "mp4"
  ContentNode.url = "http://video.ted.com/talks/podcast/DanGilbert_2004_480.mp4"

  manifest = GetManifestAsAA()
  ContentNode.streamFormat = manifest.video_stream_format
  ContentNode.url = manifest.video_stream_url

  m.Video.enableUI = false
  m.Video.content = ContentNode

  'Change the buttons
  Buttons = ["Play","Exit"]
  m.ButtonGroup.buttons = Buttons

  'Change the details
  m.Title.text = "Video with thumbnails test"
  m.Details.text = "Demo for custom player UI."

end sub

' Called when a key on the remote is pressed
function onKeyEvent(key as String, press as Boolean) as Boolean
  'print "in SimpleVideoScene.xml onKeyEvent ";key;" "; press
  if press then
    if key = "back"
      ' print "------ [back pressed] ------"
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
      ' print "------- [ok pressed] -------"
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

' MANIFEST FUNCTIONS
Function GetManifestAsAA() As Object
    manifest = {}

    text = ReadAsciiFile( "pkg:/manifest" )
    lines = text.Tokenize( Chr( 10 ) )

    for each line in lines
        line = line.Trim()
        if (line.Len() = 0)
            '** empty line
        else if (line.Left( 1 ) = "#")
            '** comment line
        else
            sepPos = line.Instr( "=" )
            if (sepPos <= 0)
                '** invalid
            else
                name = line.Mid( 0, sepPos )
                value = line.Mid( sepPos + 1 )
                manifest.AddReplace( name, value )
            end if
        end if
    end for

    return manifest
End Function

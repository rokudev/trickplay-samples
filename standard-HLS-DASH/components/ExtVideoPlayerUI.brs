' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

Function init()
    'set video node'
    m.ExtVideo = m.top
    m.top.observeField("state", "handleStateChange")
    m.top.observeField("bufferingStatus", "handleBufferingStatus")
    m.top.observeField("thumbnailTiles", "initCustomThumbnails")

    initProgressBar()
    initThumbnails()
    initLoadingBar()
end Function

Function handleStateChange(msg)
  if type(msg) = "roSGNodeEvent" and msg.getField() = "state"
      state = msg.getData()
      if state = "finished"
          ' returns to the UI page at end of stream
          m.top.visible = false
          m.ButtonGroup = m.top.getScene().findNode("ButtonGroup")
          m.ButtonGroup.setFocus(true)
      end if
      m.videoDuration = m.top.duration
  end if
end Function

Function formatNumberString(number as Integer) as String
  numberText = number.toStr()
  if number <= 0
    numberText = "00"   ' min number is 0'
  else if number < 10
    numberText = "0" + numberText
  else if number > 99
    numberText = "99"   ' max number - saturates at 99'
  end if
  return numberText
end Function

Function setTimeText(timeInSeconds) as String
  hoursText = formatNumberString( Fix(timeInSeconds / 3600) )
  minutesText = formatNumberString( Fix(timeInSeconds / 60) )
  secondsText = formatNumberString( Fix(timeInSeconds MOD 60) )

  timeText = minutesText + ":" + secondsText
  if hoursText <> "00"
    timeText = hoursText + ":" + timeText
  end if

  return timeText
end Function

' *** Progress Bar Section *** '
Function initProgressBar()
  'progress bar nodes'
  m.progress = m.top.findNode("progress")
  m.progress.visible = false

  m.progressWidth = m.top.findNode("outlineRect").width
  m.progressRect = m.top.findNode("progressRect")
  m.leftProgressLabel = m.top.findNode("leftProgressLabel")
  m.rightProgressLabel = m.top.findNode("rightProgressLabel")
  m.progressMode = m.top.findNode("progressMode")
end Function

Function showProgressBar(position)
    m.progress.visible = true
    m.progressRect.width = position * m.progressWidth / m.videoDuration
    leftPositionSeconds = position * 100 / 100
    rightPositionSeconds = m.videoDuration - leftPositionSeconds
    m.leftProgressLabel.text = setTimeText(leftPositionSeconds)
    m.rightProgressLabel.text = setTimeText(rightPositionSeconds)
    setProgressMode()
end Function

Function hideProgressBar()
    m.progress.visible = false
end Function

' ProgressMode is a UI Poster that shows if player state is playing, paused, FWD, REW'
Function setProgressMode()
  if m.trickPlaySpeed = 0
    m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_PAUSE_HD.png"
  else if m.trickPlaySpeed > 0
    if m.trickplaySpeed = 1
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx1_HD.png"
    else if m.trickplaySpeed = 2
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx2_HD.png"
    else
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx3_HD.png"
    end if
  else if m.trickPlaySpeed < 0
    if m.trickplaySpeed = -1
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx1_HD.png"
    else if m.trickplaySpeed = -2
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx2_HD.png"
    else
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx3_HD.png"
    end if
  end if
end Function

Function setProgressModePlay()
  m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_PLAY_HD.png"
end Function

' *** Thumbnails Section *** '
Function initThumbnails()
  ' thumbnails nodes'
  m.thumbnails = m.top.findNode("thumbnails")
  m.thumbnails.visible = false
  m.trickPosition = 0
  m.trickOffset = 0
  m.trickInterval = 10  ' Default will be overriden by thumbnail interval in manifest'

  m.trickPlayTimer = createObject("roSGNode", "Timer")
  m.trickPlayTimer.duration = 1
  m.trickPlayTimer.repeat = True
  m.trickPlayTimer.observeField("fire", "handleTrickPlayTimer")

  'array with thumbnails'
  poster0 = m.top.findNode("poster_thumb_minus2")
  poster1 = m.top.findNode("poster_thumb_minus1")
  poster2 = m.top.findNode("poster_thumb_center")
  poster3 = m.top.findNode("poster_thumb_plus1")
  poster4 = m.top.findNode("poster_thumb_plus2")

  m.arrayPosters = []
  m.arrayPosters.push(poster0)
  m.arrayPosters.push(poster1)
  m.arrayPosters.push(poster2)
  m.arrayPosters.push(poster3)
  m.arrayPosters.push(poster4)

  resetSeekLogic()
end Function

Function resetSeekLogic()
  m.trickPlaySpeed = 0
  m.trickOffset = 0
  m.trickPlayTimer.duration = 1
end Function

Function isSeeking() as boolean
  return m.trickPlaySpeed <> 0 or m.trickOffset <> 0
end Function

Function startSeeking()  ' key is either "fastforward" or "rewind"
    m.trickPlayTimer.control = "STOP"

    if m.trickPlaySpeed <> 0
        m.trickPlayTimer.duration = 1 / abs(m.trickPlaySpeed)
        m.trickPlayTimer.control = "START"
    else
        m.TrickPlayTimer.duration = 1
    end if
end Function

' The pauseSeeking function is called only when the user presses the "left" or
' "right" button on the remote. The m.trickPlaySpeed variable is set to 0 initially
' and modified in order for the updateThumbnails() function to know what direction
' to move the thumbnails in. The m.trickPlaySpeed is reset to 0 when the update
' is complete.
Function pauseSeeking(key, position)  ' key is either "left" or "right"
  m.trickPlayTimer.control = "STOP"
  m.trickPlaySpeed = 0
  showThumbnails(position)
  if key = "right"    ' shift thumbnails to the left - forward
    m.trickPlaySpeed = 1
    if position + m.trickInterval <= m.videoDuration
        m.trickOffset += m.trickInterval
    else
        m.trickOffset = m.videoDuration - m.ExtVideo.position
    end if
  else if key = "left"    ' shift thumbnails to the right - reverse
    m.trickPlaySpeed = -1
    if position - m.trickInterval >= 0
        m.trickOffset -= m.trickInterval
    else
        m.trickOffset = m.ExtVideo.position * -1
    end if
  end if
  updateThumbnails()
  m.trickPlaySpeed = 0
  showProgressBar(m.ExtVideo.position + m.trickOffset)
end Function

' We finished performing trickplay functions by pressing "play" or "ok" button.
' We can now seek to the specified position and reset the seeking functionality.
Function endSeeking()
  m.trickPlayTimer.control = "STOP"

  m.ExtVideo.seek = m.ExtVideo.position + m.trickOffset

  resetSeekLogic()
  setProgressModePlay()
end Function

' Display the thumbnails. The channel needs to calculate the current center sprite
' index and the row/column index within the sprite sheet to display the correct
' thumbnail tile. The rest of the thumbnails will be rendered based on what the
' center thumbnail displays to reduce the need to recalculate indexes for every
' poster.
Function showThumbnails(position) as void
    m.centerSpriteIndex = getSpriteIndex(position)
    'skip any additional show Thumbnails if center sprite index is -1'
    if m.centerSpriteIndex = -1 then return

    positionToIndexes(position)
    renderPosters()
    m.thumbnails.visible = true
end Function

Function hideThumbnails()
    m.thumbnails.visible = false
end Function

' The callback function when the timer fires to update trickplay position and thumbnails.
' If the m.trickPlaySpeed variable is positive, it is fast forwarding. If the m.trickPlaySpeed
' variable is negative, it is rewinding. If the m.trickplaySpeed variable equals 0, the content
' is in a paused state.
Function handleTrickPlayTimer()
    if m.trickPlaySpeed > 0
        if m.ExtVideo.position + m.trickOffset + m.trickInterval <= m.videoDuration
            m.trickOffset += m.trickInterval
        else
            m.trickOffset = m.videoDuration - m.ExtVideo.position ' Seek to t = duration
        end if
    else if m.trickPlaySpeed < 0
        if m.ExtVideo.position + m.trickOffset - m.trickInterval >= 0
            m.trickOffset -= m.trickInterval
        else
            m.trickOffset = m.ExtVideo.position * -1 ' Seek to t = 0
        end if
    end if
    if m.centerSpriteIndex <> -1 then
      updateThumbnails()
    end if
    showProgressBar(m.ExtVideo.position + m.trickOffset)
end Function

' *** Loading Bar Section *** '
Function initLoadingBar()
  m.loadingPercentage = 0
  m.loading = m.top.findNode("loading")
  m.loading.visible = false
  m.loadingWidth = m.top.findNode("loadOutlineRect").width
  m.loadingProgressRect = m.top.findNode("loadProgressRect")
end Function

Function showLoadingBar()
  m.loading.visible = true
  m.loadingProgressRect.width = m.loadingPercentage * m.loadingWidth / 100
end Function

Function hideLoadingBar()
  m.loading.visible = false
  m.loadingPercentage = 0
end Function

Function handleBufferingStatus(msg)
  bufferingStatus = msg.getData()
  if bufferingStatus <> invalid
    m.loadingPercentage = bufferingStatus.percentage

#if thumbnailDebug
    ? "buffering(percentage): "; m.loadingPercentage
#end if

    showLoadingBar()
    if m.loadingPercentage = 100
      hideLoadingBar()
      hideProgressBar()
      hideThumbnails()
    end if
  end if
end Function

' The ExtVideoPlayerUI object handles all of the trickplay button functionality.
'
' A fast forward or rewind button press will increment or decrement the trickplay
' speed, respectively. If the absolute value of the trickplay speed is greater than
' 3, the trickplay resets to 1 (fast forward) or -1 (rewind). If the trickplay speed
' is equal to 0, we treat this as a paused state. A timer handles when to fire the event
' to update the trickplay position / thumbnail scrubbing.
'
' A left or right button press will pause playback and rewind or fast forward one time
' increment, respectively. The channel determines the time increment by the PTS offset
' between each thumbnail tile. This is mainly handled in the pauseSeeking function.
Function onKeyEvent(key as String, press as Boolean) as Boolean  'Maps back button to leave video
    ? "ExtVideoPlayerUI onKeyEvent(): "; key
    handled = false
    if press
        if key = "fastforward" or key = "rewind"
            m.ExtVideo.control = "pause"
            position = m.ExtVideo.position + m.trickOffset

            if key = "fastforward"
                m.trickPlaySpeed++
                if m.trickPlaySpeed > 3
                    m.trickPlaySpeed = 1
                end if
            else if key = "rewind"
                m.trickPlaySpeed--
                if m.trickPlaySpeed < -3
                    m.trickPlaySpeed = -1
                end if
            end if

            if position <= m.videoDuration and position >= 0 ' block additional fast forwards from going off the progress bar
              showProgressBar(position)
              startSeeking()
              showThumbnails(position)
            end if
            handled = true
        else if key = "left" or key = "right"
            m.ExtVideo.control = "pause"
            position = m.ExtVideo.position + m.trickOffset
            pauseSeeking(key, position)
            handled = true
        else if key = "play" or key = "OK"
            if m.ExtVideo.state = "playing"
                showProgressBar(m.ExtVideo.position)
                m.ExtVideo.control = "pause"
            else
                if isSeeking()
                    showLoadingBar()
                    endSeeking()
                else
                    m.ExtVideo.control = "resume"
                    hideProgressBar()
                    hideThumbnails()
                end if
            end if
            handled = true
        else if key = "back"
            m.ExtVideo.control = "stop"
            hideProgressBar()
            hideThumbnails()
        end if
    end if

	return handled
end Function

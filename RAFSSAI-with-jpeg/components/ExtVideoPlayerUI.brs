' ********** Copyright 2016-2019 Roku Corp.  All Rights Reserved. **********

Function init()
    'set video node'
    m.ExtVideo = m.top
    m.top.observeField("state", "handleStateChange")
    m.top.observeField("bufferingStatus", "handleBufferingStatus")

    initProgressBar()
    initThumbnails()       ' hostPefix and trickInterval are passed in from interface fields'

    initLoadingBar()

    'SSAI adPods info'
    m.adPods = invalid
    m.top.observeField("adPods", "handleAdPodUpdate")
    m.initPos = 0
end Function

Function handleStateChange(msg)
  if type(msg) = "roSGNodeEvent" and msg.getField() = "state"
      state = msg.getData()
      if state = "finished"
          m.top.getScene().exitApp = true
      else if m.ExtVideo.thumbnailHostPrefix <> ""
          ' This is to take in the video node thumbnails and content duration
          ' Is there a better way? '
          m.hostPrefix = m.ExtVideo.thumbnailHostPrefix
          m.trickInterval = m.ExtVideo.thumbnailIntervalInSecs
      else
          m.hostPrefix = invalid
          m.trickInterval = 5
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

Function setProgressMode()
  if m.trickPlaySpeed = 0
    m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_PAUSE_HD.png"
  else if m.trickplayDirection = "forward"
    if m.trickplaySpeed = 1
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx1_HD.png"
    else if m.trickplaySpeed = 2
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx2_HD.png"
    else
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_FWDx3_HD.png"
    end if
  else if m.trickplayDirection = "reverse"
    if m.trickplaySpeed = 1
      m.progressMode.uri = "pkg:/images/TrickPlay_ButtonMode_REWx1_HD.png"
    else if m.trickplaySpeed = 2
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

  ' Timer is used during ffwd/rew, thumbnails move when the fire event hits'
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
  ' ffwd/rew happen from a paused state, i.e. m.trickplayDirection = "paused"
  m.trickplayDirection = "paused"
  m.trickPlaySpeed = 0
  m.trickPlayTimer.duration = 1
end Function

Function isSeeking() as boolean
  return m.trickplayDirection <> "paused"
end Function

Function startSeeking(key)  ' key is either "fastforward" or "rewind"
  if m.trickplayDirection = "paused"
      m.trickplaySpeed = 1
      m.trickPlayTimer.duration = 1 / m.trickPlaySpeed
      ' set the trickplay direction'
      if key = "fastforward" or key = "forward"
        m.trickplayDirection = "forward"
      else
        m.trickplayDirection = "reverse"
      end if

      m.trickPlayTimer.control = "START"
  else if key = "fastforward" and m.trickplayDirection <> "forward" or key = "rewind" and m.trickplayDirection <> "reverse"
      pauseSeeking(key, m.trickPosition * m.trickInterval)
  else
      ' set the trick play speed'
      m.trickPlaySpeed += 1
      if m.trickPlaySpeed > 3 ' saturate trickplay speed at 3x'
          m.trickPlaySpeed = 1
      end if
      m.trickPlayTimer.control = "STOP"
      m.trickPlayTimer.duration = 1 / m.trickPlaySpeed
      m.trickPlayTimer.control = "START"
  end if
  print "trickPlaySpeed= "; m.trickPlaySpeed
end Function

Function pauseSeeking(key, position)  ' key is either "left" or "right"
  m.trickPlayTimer.control = "STOP"
  m.trickPlaySpeed = 0
  if m.trickplayDirection = "paused"
    showThumbnails(position)
    if key = "right"
      m.trickplayDirection = "forward"
    else
      m.trickplayDirection = "reverse"
    end if
  else if key = "right" or key = "fastforward"    ' shift thumbnails to the left - forward
    if m.trickPosition < Fix((m.videoDuration / m.trickInterval) + 1)
        m.trickPosition += 1
        shiftThumbnailsLeft()
    end if
    m.trickplayDirection = "forward"
  else if key = "left" or key = "rewind"    ' shift thumbnails to the right - reverse
    if m.trickPosition > 0
        m.trickPosition -= 1
        shiftThumbnailsRight()
    end if
    m.trickplayDirection = "reverse"
  end if
  showProgressBar(position)
end Function

Function endSeeking()
  m.trickPlayTimer.control = "STOP"
  ' is there a better way to force seek position?'
  m.ExtVideo.control = "stop"
  m.ExtVideo.control = "play"
  seekPosition = Cdbl(m.trickPosition * m.trickInterval)
  adinfo = getAdBreakAtPosition(seekPosition)
  if adinfo <> invalid and ((seekPosition >= adinfo.start and seekPosition <= adinfo.end))
    if m.initPos <> 0 and seekPosition > m.initPos
      seekPosition = adinfo.start
      ? "seek fwd - begin of ad, position= "; seekPosition
    else if m.initPos <> 0 and m.initPos < seekPosition
      seekPosition = adinfo.end + 3   ' until can get thumbnails aligned to iframes'
      ? "seek rew - end of ad, position= "; seekPosition
    else
      seekPosition = m.ExtVideo.position
    end if
  else if adinfo <> invalid and m.initPos <> 0 and seekPosition > adinfo.start ' user skipped ad, throw them back
      seekPosition = adinfo.start
  end if
  m.ExtVideo.seek = seekPosition
  resetSeekLogic()
  setProgressModePlay()
end Function

Function showThumbnails(position)
    m.trickPosition = Fix(position / 5) + 1
    ? "m.trickPosition= ", m.trickPosition

    'don't display thumbnails if m.hostPrefix is not set
    if m.hostPrefix = invalid
      return 0
    end if

    m.thumbnails.visible = true

    ' calculate the start index, special handling if m.trickPosition < 3
    ' the arrayPosters have 5 slots, don't fill lower two slots at beginning of the stream
    startIndex = 0
    endIndex = 4
    if m.trickPosition < 3
      startIndexData = [3, 2, 1]
      startIndex = startIndexData[m.trickPosition]
    end if

    adinfo = getAdBreakAtPosition(position)
    if adinfo <> Invalid
      ? "ad start= "; adinfo.start; ", ad end= "; adinfo.end
    end if
    for i = startIndex to endIndex
      ' array index 2 is the current position (poster_thumb_center), other indexes are offset'
      position = (m.trickPosition + i - 2) * m.trickInterval
      if adinfo <> invalid and position >= adinfo.start and position <= adinfo.end
        m.arrayPosters[i].uri = ""
      else
        m.arrayPosters[i].uri = m.hostPrefix + "thumb-" + (m.trickPosition + i - 2).toStr() + ".jpg"
      end if
      ? "show - poster i="; i; ", position="; position; ", uri="; m.arrayPosters[i].uri
    end for
end Function

Function hideThumbnails()
    m.thumbnails.visible = false
end Function

Function shiftThumbnailsLeft()    ' forward direction'
  'don't display thumbnails if m.hostPrefix is not set
  if m.hostPrefix = invalid
    return 0
  end if

  m.arrayPosters[0].uri = m.arrayPosters[1].uri
  m.arrayPosters[1].uri = m.arrayPosters[2].uri
  m.arrayPosters[2].uri = m.arrayPosters[3].uri
  m.arrayPosters[3].uri = m.arrayPosters[4].uri

  position = (m.trickPosition + 2) * m.trickInterval
  adinfo = getAdBreakAtPosition(position)
  if adinfo <> Invalid and position >= adinfo.start
    ? "ad start= "; adinfo.start; ", ad end= "; adinfo.end
  end if

  if adinfo <> invalid and position >= adinfo.start and position <= adinfo.end
    m.arrayPosters[4].uri = ""
  else
    m.arrayPosters[4].uri = m.hostPrefix + "thumb-" + (m.trickPosition + 2).toStr() + ".jpg"
  end if
  ? "shiftleft - poster 4, position="; position; ", uri="; m.arrayPosters[4].uri
end Function

Function shiftThumbnailsRight()   ' reverse direction'
  'don't display thumbnails if m.hostPrefix is not set
  if m.hostPrefix = invalid
    return 0
  end if

  m.arrayPosters[4].uri = m.arrayPosters[3].uri
  m.arrayPosters[3].uri = m.arrayPosters[2].uri
  m.arrayPosters[2].uri = m.arrayPosters[1].uri
  m.arrayPosters[1].uri = m.arrayPosters[0].uri

  position = (m.trickPosition - 2) * m.trickInterval
  adinfo = getAdBreakAtPosition(position)
  if adinfo <> Invalid
    ? "ad start= "; adinfo.start; ", ad end= "; adinfo.end
  end if

  if adinfo <> invalid and position >= adinfo.start and position <= adinfo.end
    m.arrayPosters[0].uri = ""
  else
    m.arrayPosters[0].uri = m.hostPrefix + "thumb-" + (m.trickPosition - 2).toStr() + ".jpg"
  end if
  ? "shiftright - poster 0, position="; position; ", uri="; m.arrayPosters[0].uri
end Function

Function handleTrickPlayTimer() as Void
    if m.trickplayDirection = "forward"
        if m.trickPosition * m.trickInterval + m.trickInterval >= m.videoDuration ' handle fast foward overflow
            shiftThumbnailsLeft()
            showProgressBar(m.videoDuration)
            pauseSeeking("right", m.videoDuration)
            return
        else if m.trickPosition < Fix((m.videoDuration / m.trickInterval) + 1)
            m.trickPosition += 1
            shiftThumbnailsLeft()
        end if
    else if m.trickplayDirection = "reverse"
        if m.trickPosition > 0
            m.trickPosition -= 1
            shiftThumbnailsRight()
        else
            pauseSeeking("left", 0)
        end if
    end if
    showProgressBar(m.trickPosition * m.trickInterval)
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
    print "buffering - percentage= "; m.loadingPercentage
    showLoadingBar()
    if m.loadingPercentage = 100
      hideLoadingBar()
      hideProgressBar()
      hideThumbnails()
    end if
  end if
end Function

' *** Special ad handling section *** '
Function handleAdPodUpdate(msg)
  m.adPods = msg.GetData()
  for each adbreak in m.adPods
    print adbreak
  end for
end Function

Function getAdBreakAtPosition(position) as object
  adinfo = invalid
  if m.adPods <> invalid
    aheadPosition = position + 4 * m.trickInterval
    behindPosition = position - 4 * m.trickInterval
    for each adbreak in m.adPods
      ' The following 4 ifs could be a single on a long line

      if position >= adbreak.renderTime and position <= (adbreak.renderTime + adbreak.duration)
        adinfo = {start: adbreak.renderTime
                  end: (adbreak.renderTime + adbreak.duration) }
        exit for
      else if aheadPosition >= adbreak.renderTime and aheadPosition <= (adbreak.renderTime + adbreak.duration)
        adinfo = {start: adbreak.renderTime
                  end: (adbreak.renderTime + adbreak.duration) }
        exit for
      else if behindPosition >= adbreak.renderTime and position <= (adbreak.renderTime + adbreak.duration)
        adinfo = {start: adbreak.renderTime
                  end: (adbreak.renderTime + adbreak.duration) }
        exit for
      else if position >= adbreak.renderTime and adbreak.renderTime <> 0 and m.initPos <= adBreak.renderTime' skipped any ad but the first, go back
        adinfo = {start: adbreak.renderTime
                  end: (adbreak.renderTime + adbreak.duration) }
        exit for
      end if

    end for
  end if
  return adinfo
end Function

Function onKeyEvent(key as String, press as Boolean) as Boolean  'Maps back button to leave video
    ? "onKeyEvent: "; key
    handled = false
    if press
        if key = "fastforward" or key = "rewind"
          if not isSeeking()
            position = m.ExtVideo.position
          else
            position = m.trickPosition * m.trickInterval
            if key = "rewind" then position -= m.trickInterval
          end if

          if m.trickPlaySpeed = 0 then m.initPos = position

          if position < m.videoDuration ' block additional fast forwards from going off the progress bar
            showProgressBar(position)
            startSeeking(key)
            showThumbnails(position)
          end if

        else if key = "left" or key = "right"
          if not isSeeking()
            position = m.ExtVideo.position
          else
            position = m.trickPosition * m.trickInterval
          end if
          pauseSeeking(key, position)
        else if key = "play" or key = "OK"
            if m.ExtVideo.state = "playing"
                m.initPos = m.ExtVideo.position
                showProgressBar(m.ExtVideo.position)
                m.ExtVideo.control = "pause"
                m.trickPlayDirection = "paused"
            else
                if isSeeking()
                    showLoadingBar()
                    endSeeking()
                else
                    m.ExtVideo.control = "resume"
                    hideProgressBar()
                end if
            end if
        end if
    end if

	return handled
end Function

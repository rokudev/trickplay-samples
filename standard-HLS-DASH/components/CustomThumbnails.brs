' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

' initCustomThumbnails
' Retrieve the thumbnail data

sub initCustomThumbnails(msg as object)
#if useMergeGroupsWorkaround
    origData = msg.getData()
    m.customThumbnailData = mergeEntriesWithSameBandwidth(origData)
#else
    m.customThumbnailData = msg.getData()
#end if

#if thumbnailDebug
    dumpThumbnailData(m.customThumbnailData)
#end if

    selectThumbnail()
    m.trickInterval = m.selectedThumbnailData.duration / (m.selectedThumbnailData.htiles * m.selectedThumbnailData.vtiles)
    initPosterSizes()
    initTranslatePosters()
end sub

' function that merge multiple entries in tileThumbnails with same bandwidth into one,
' because firmware creates one entry in the AA per duration'
function mergeEntriesWithSameBandwidth(data as Object) as object
    ' Validate data for merge purposes'
    aa = data.Items()
    key0 = aa[0].key
    bw = aa[0].value.bandwidth.toStr()
    r = CreateObject("roRegex", "_+","")
    aw = r.split(key0)
    if aw[1] <> bw or aa.count() = 1
      return data
    end if

    ' First extract the first number from tileThumbnails key'
    regex = CreateObject("roRegex", "\d+", "")
    arrayOfNumbers = []
    for each item in data
        a = regex.match(item)
        num = a[0].toInt()
        arrayOfNumbers.push(num)
    end for
    arrayOfNumbers.sort()

    ' Build single array of tiles ordered by numbers in arrayOfNumbers, number_bandwidth'
    tiles = []
    for i=0 to arrayOfNumbers.count()-1
      index = arrayOfNumbers[i].toStr() + "_" + bw.toStr()
      print "index= "; index;
      for j=0  to data[index].tiles.count()-1
        tiles.push(data[index].tiles[j])
      end for
    end for

    ' return result with a single entry equivalent to data[0_bw] but with all tiles'
    key = "0_" + bw
    data[key].tiles = tiles
    result = {}
    result.addReplace(key, data[key])

    return result
end function


' For the sake of this example, we will just use the last thumbnail tiles in the
' list of available thumbnail tiles. The channel should have some logic to select
' the thumbnails that are needed based on certain heuristics (e.g. bandwidth)
sub selectThumbnail()
    selectedData = thumbnailEntryForTextureMapLimits(m.customThumbnailData)
    if selectedData <> invalid
      m.selectedThumbnailData = selectedData
    end if
end sub

' Initialize the size of the posters.
' The idea here is that the actual sprite sheet will be scaled to obtail a tile size
' that the channel desires, but will be later specified what needs to actually render
' on screen, according to the clippingRect field of the poster node.
sub initPosterSizes()
    ' We want to change the poster so that each "tile" is 320x180 for an fhd resolution
    m.POSTER_WIDTH = 320
    m.POSTER_HEIGHT = 180

    ' The exception to the poster size is the center poster, as it will be slightly
    ' bigger than the other tiles to give "focus" to the center poster to indicate
    ' it's current position.
    m.POSTER_WIDTH_CENTER = m.POSTER_WIDTH * 1.2
    m.POSTER_HEIGHT_CENTER = m.POSTER_HEIGHT * 1.2

    m.arrayPosters[0].width = m.POSTER_WIDTH * m.selectedThumbnailData.htiles
    m.arrayPosters[0].height = m.POSTER_HEIGHT * m.selectedThumbnailData.vtiles

    m.arrayPosters[1].width = m.POSTER_WIDTH * m.selectedThumbnailData.htiles
    m.arrayPosters[1].height = m.POSTER_HEIGHT * m.selectedThumbnailData.vtiles

    m.arrayPosters[2].width = m.POSTER_WIDTH_CENTER * m.selectedThumbnailData.htiles
    m.arrayPosters[2].height = m.POSTER_HEIGHT_CENTER * m.selectedThumbnailData.vtiles

    m.arrayPosters[3].width = m.POSTER_WIDTH * m.selectedThumbnailData.htiles
    m.arrayPosters[3].height = m.POSTER_HEIGHT * m.selectedThumbnailData.vtiles

    m.arrayPosters[4].width = m.POSTER_WIDTH * m.selectedThumbnailData.htiles
    m.arrayPosters[4].height = m.POSTER_HEIGHT * m.selectedThumbnailData.vtiles
end sub

' Initialize the translation of the posters.
' Translation comes into play when the sprite sheet changes clippingRect values, which
' is necessary in order to render the next tile and have it positioned in the same
' position where the previous tile was.
sub initTranslatePosters()
    m.arrayPosters[0].addField("x", "float", false)
    m.arrayPosters[0].addField("y", "float", false)
    m.arrayPosters[0].x = (1920 - m.POSTER_WIDTH) * 0
    m.arrayPosters[0].y = (1080 - m.POSTER_HEIGHT) / 2
    m.arrayPosters[0].translation = [m.arrayPosters[0].x, m.arrayPosters[0].y]

    m.arrayPosters[1].addField("x", "float", false)
    m.arrayPosters[1].addField("y", "float", false)
    m.arrayPosters[1].x = (1920 - m.POSTER_WIDTH) * 0.25
    m.arrayPosters[1].y = (1080 - m.POSTER_HEIGHT) / 2
    m.arrayPosters[1].translation = [m.arrayPosters[1].x, m.arrayPosters[1].y]

    m.arrayPosters[2].addField("x", "float", false)
    m.arrayPosters[2].addField("y", "float", false)
    m.arrayPosters[2].x = (1920 - m.POSTER_WIDTH_CENTER) / 2
    m.arrayPosters[2].y = (1080 - m.POSTER_HEIGHT_CENTER) / 2
    m.arrayPosters[2].translation = [m.arrayPosters[2].x, m.arrayPosters[2].y]

    m.arrayPosters[3].addField("x", "float", false)
    m.arrayPosters[3].addField("y", "float", false)
    m.arrayPosters[3].x = (1920 - m.POSTER_WIDTH) * 0.75
    m.arrayPosters[3].y = (1080 - m.POSTER_HEIGHT) / 2
    m.arrayPosters[3].translation = [m.arrayPosters[3].x, m.arrayPosters[3].y]

    m.arrayPosters[4].addField("x", "float", false)
    m.arrayPosters[4].addField("y", "float", false)
    m.arrayPosters[4].x = (1920 - m.POSTER_WIDTH) * 1
    m.arrayPosters[4].y = (1080 - m.POSTER_HEIGHT) / 2
    m.arrayPosters[4].translation = [m.arrayPosters[4].x, m.arrayPosters[4].y]
end sub

' Obtain the index of the array containing the sprite sheets, according to what
' the current position is. This only gets called to retrieve the center thumbnail's
' sprite sheet in order to only do the calculation on one poster. The big assumption
' here is that position is greater than 0 and less than the duration of the content.
function getSpriteIndex(position as double) as integer
    if m.selectedThumbnailData = invalid then return -1
    if position < 0 then return 0
    if position > m.videoDuration then return m.selectedThumbnailData.tiles.count() - 1

    for i = 0 to m.selectedThumbnailData.tiles.count() - 1
        if position >= i * m.selectedThumbnailData.duration
            if i + 1 < m.selectedThumbnailData.tiles.count()
                if position < (i + 1) * m.selectedThumbnailData.duration
                    return i
                end if
            else
                return i
            end if
        else
            return i - 1
        end if
    end for

    return -1
end function

' Converts a position to a row/column index.
sub positionToIndexes(position as double)
#if thumbnailDebug
    ? "positionToIndexes()"
    ? "position= "; position
#endif
    if m.selectedThumbnailData = invalid then return

    tileDuration = m.selectedThumbnailData.duration / (m.selectedThumbnailData.vtiles * m.selectedThumbnailData.htiles)
    positionInSpriteSheet = position MOD m.selectedThumbnailData.duration
#if thumbnailDebug
    ? "positionInSpriteSheet= "; positionInSpriteSheet
#endif
    m.rowIndex = Int(positionInSpriteSheet / (tileDuration * m.selectedThumbnailData.htiles))
    m.columnIndex = Int(positionInSpriteSheet / tileDuration) MOD m.selectedThumbnailData.htiles

#if thumbnailDebug
    ? "m.rowIndex: " + m.rowIndex.toStr()
    ? "m.columnIndex: " + m.columnIndex.toStr()
#endif

end sub

' Will update the thumbnails based on whether the content is moving forward or
' rewinding.
function updateThumbnails()
    if m.trickPlaySpeed > 0
        m.columnIndex++

        if m.columnIndex > m.selectedThumbnailData.htiles - 1
            m.columnIndex = 0
            m.rowIndex++
            if m.rowIndex > m.selectedThumbnailData.vtiles - 1
                m.rowIndex = 0
                m.centerSpriteIndex++
                if m.centerSpriteIndex >= m.selectedThumbnailData.tiles.count()
                    m.centerSpriteIndex--
                    m.columnIndex = m.selectedThumbnailData.htiles - 1
                    m.rowIndex = m.selectedThumbnailData.vtiles - 1
                    m.trickPlaySpeed = 0
                    m.trickPlayTimer.control = "stop"
                end if
            end if
        end if
    else if m.trickPlaySpeed < 0
        m.columnIndex--

        if m.columnIndex < 0
            m.columnIndex = m.selectedThumbnailData.htiles - 1
            m.rowIndex--
            if m.rowIndex < 0
                m.rowIndex = m.selectedThumbnailData.vtiles - 1
                m.centerSpriteIndex--
                if m.centerSpriteIndex < 0
                    m.centerSpriteIndex++
                    m.columnIndex = 0
                    m.rowIndex = 0
                    m.trickPlaySpeed = 0
                    m.trickPlayTimer.control = "stop"
                end if
            end if
        end if
    end if

    renderPosters()
    indexToPosition()
end function

' Debug function to check if the calculation of current row/column/centerSprite index
' is correct.
sub indexToPosition()
    tileDuration = m.selectedThumbnailData.duration / (m.selectedThumbnailData.vtiles * m.selectedThumbnailData.htiles)
    'position = (m.centerSpriteIndex * m.selectedThumbnailData.duration) + (m.rowIndex * m.selectedThumbnailData.vtiles * tileDuration) + (m.columnIndex * tileDuration)
    position = (m.centerSpriteIndex * m.selectedThumbnailData.duration) + (m.rowIndex * m.selectedThumbnailData.htiles * tileDuration) + (m.columnIndex * tileDuration)

#if thumbnailDebug
    ? "indexToPosition()"
    ? "* start position of sprite=" + m.centerSpriteIndex.toStr() + " row=" + m.rowIndex.toStr() + " column=" + m.columnIndex.toStr() + " ==> " + position.toStr() + " sec"
    ? "* video position: " + m.extvideo.position.toStr() + " sec"
    ? "* offset: " + m.trickOffset.toStr() + " sec"
#end if

end sub

' Renders the thumbnail posters on what the current row/column/centerSprite index is.
' One thing to keep in mind is this works only when the sprite sheet is at minimum a
' 1x2 sprite sheet, as it currently will only go back one sprite sheet to determine
' the previous/next sprite sheet from the "current" center poster.
sub renderPosters()
#if thumbnailDebug
      ? "calling renderPosters()"
#end if
    ' updating left2 poster...
    columnIndexLeft2 = m.columnIndex - 2
    rowIndexLeft2 = m.rowIndex
    spriteIndex = m.centerSpriteIndex

    if columnIndexLeft2 < 0
        rowIndexLeft2--
        if rowIndexLeft2 < 0
            ' No more available tiles in this sprite sheet...
            ' Fetch the next sprite sheet, if available
#if thumbnailDebug
    ? "renderPosters(): fetch next sprite sheet if available."
#end if
            rowIndexLeft2 = m.selectedThumbnailData.vtiles - 1
            spriteIndex--
        end if

        columnIndexLeft2 = m.selectedThumbnailData.htiles - abs(columnIndexLeft2)
        m.arrayPosters[0].clippingRect = [columnIndexLeft2 * m.POSTER_WIDTH, rowIndexLeft2 * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    else
        m.arrayPosters[0].clippingRect = [columnIndexLeft2 * m.POSTER_WIDTH, m.rowIndex * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    end if

    newTranslationX = m.arrayPosters[0].x - (m.POSTER_WIDTH * columnIndexLeft2)
    newTranslationY = m.arrayPosters[0].y - (m.POSTER_HEIGHT * rowIndexLeft2)
    m.arrayPosters[0].translation = [newTranslationX, newTranslationY]
    if spriteIndex < 0
        m.arrayPosters[0].uri = ""
#if thumbnailDebug
        ? "renderPosters(): arrayposter[0] is empty"
#end if
    else
        m.arrayPosters[0].uri = m.selectedThumbnailData.tiles[spriteIndex][0]
    end if

    ' updating left1 poster...
    columnIndexLeft1 = m.columnIndex - 1
    rowIndexLeft1 = m.rowIndex
    spriteIndex = m.centerSpriteIndex

    if columnIndexLeft1 < 0
        rowIndexLeft1--
        if rowIndexLeft1 < 0
            ' No more available tiles in this sprite sheet...
            ' Fetch the next sprite sheet, if available
            rowIndexLeft1 = m.selectedThumbnailData.vtiles - 1
            spriteIndex--
        end if

        columnIndexLeft1 = m.selectedThumbnailData.htiles - abs(columnIndexLeft1)
        m.arrayPosters[1].clippingRect = [columnIndexLeft1 * m.POSTER_WIDTH, rowIndexLeft1 * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    else
        m.arrayPosters[1].clippingRect = [columnIndexLeft1 * m.POSTER_WIDTH, m.rowIndex * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    end if

    newTranslationX = m.arrayPosters[1].x - (m.POSTER_WIDTH * columnIndexLeft1)
    newTranslationY = m.arrayPosters[1].y - (m.POSTER_HEIGHT * rowIndexLeft1)
    m.arrayPosters[1].translation = [newTranslationX, newTranslationY]
    if spriteIndex < 0
        m.arrayPosters[1].uri = ""
#if thumbnailDebug
        ? "renderPosters(): arrayposter[1] is empty"
#end if
    else
        m.arrayPosters[1].uri = m.selectedThumbnailData.tiles[spriteIndex][0]
    end if

    ' updating center poster...
    m.arrayPosters[2].clippingRect = [m.columnIndex * m.POSTER_WIDTH_CENTER, m.rowIndex * m.POSTER_HEIGHT_CENTER, m.POSTER_WIDTH_CENTER, m.POSTER_HEIGHT_CENTER]
    newTranslationX = m.arrayPosters[2].x - (m.POSTER_WIDTH_CENTER * m.columnIndex)
    newTranslationY = m.arrayPosters[2].y - (m.POSTER_HEIGHT_CENTER * m.rowIndex)
    m.arrayPosters[2].translation = [newTranslationX, newTranslationY]
    m.arrayPosters[2].uri = m.selectedThumbnailData.tiles[m.centerSpriteIndex][0]

    ' updating right1 poster...
    columnIndexRight1 = m.columnIndex + 1
    rowIndexRight1 = m.rowIndex
    spriteIndex = m.centerSpriteIndex

    if columnIndexRight1 > m.selectedThumbnailData.htiles - 1
        rowIndexRight1++
        if rowIndexRight1 > m.selectedThumbnailData.vtiles - 1
            ' No more available tiles in this sprite sheet...
            ' Fetch the next sprite sheet, if available
            rowIndexRight1 = 0
            spriteIndex++
        end if

        columnIndexRight1 = ((columnIndexRight1 + 1) MOD m.selectedThumbnailData.htiles) - 1
        m.arrayPosters[3].clippingRect = [columnIndexRight1 * m.POSTER_WIDTH, rowIndexRight1 * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    else
        m.arrayPosters[3].clippingRect = [columnIndexRight1 * m.POSTER_WIDTH, m.rowIndex * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    end if

    newTranslationX = m.arrayPosters[3].x - (m.POSTER_WIDTH * columnIndexRight1)
    newTranslationY = m.arrayPosters[3].y - (m.POSTER_HEIGHT * rowIndexRight1)
    m.arrayPosters[3].translation = [newTranslationX, newTranslationY]
    if spriteIndex > m.selectedThumbnailData.tiles.count() - 1
        m.arrayPosters[3].uri = ""
#if thumbnailDebug
        ? "renderPosters(): arrayposter[3] is empty"
#end if
    else
        m.arrayPosters[3].uri = m.selectedThumbnailData.tiles[spriteIndex][0]
    end if

    ' updating right2 poster...
    columnIndexRight2 = m.columnIndex + 2
    rowIndexRight2 = m.rowIndex
    spriteIndex = m.centerSpriteIndex

    if columnIndexRight2 > m.selectedThumbnailData.htiles - 1
        rowIndexRight2++
        if rowIndexRight2 > m.selectedThumbnailData.vtiles - 1
            ' No more available tiles in this sprite sheet...
            ' Fetch the next sprite sheet, if available
            rowIndexRight2 = 0
            spriteIndex++
        end if

        columnIndexRight2 = ((columnIndexRight2 + 1) MOD m.selectedThumbnailData.htiles) - 1
        m.arrayPosters[4].clippingRect = [columnIndexRight2 * m.POSTER_WIDTH, rowIndexRight2 * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    else
        m.arrayPosters[4].clippingRect = [columnIndexRight2 * m.POSTER_WIDTH, m.rowIndex * m.POSTER_HEIGHT, m.POSTER_WIDTH, m.POSTER_HEIGHT]
    end if

    newTranslationX = m.arrayPosters[4].x - (m.POSTER_WIDTH * columnIndexRight2)
    newTranslationY = m.arrayPosters[4].y - (m.POSTER_HEIGHT * rowIndexRight2)
    m.arrayPosters[4].translation = [newTranslationX, newTranslationY]
    if spriteIndex > m.selectedThumbnailData.tiles.count() - 1
        m.arrayPosters[4].uri = ""
#if thumbnailDebug
        ? "renderPosters(): arrayposter[4] is empty"
#end if
    else
        m.arrayPosters[4].uri = m.selectedThumbnailData.tiles[spriteIndex][0]
    end if

#if thumbnailDebug
    ? "renderPosters() - array poster URLs:"
    ? "   arrayPoster[0]: " ; m.arrayPosters[0].uri
    ? "   arrayPoster[1]: " ; m.arrayPosters[1].uri
    ? "   arrayPoster[2]: " ; m.arrayPosters[2].uri
    ? "   arrayPoster[3]: " ; m.arrayPosters[3].uri
    ? "   arrayPoster[4]: " ; m.arrayPosters[4].uri
#end if
    ' TODO: inspect uri of the poster if it's visible in the row index column...
end sub

' THUMBNAIL STREAM META FUNCTIONS

sub dumpThumbnailData(thumbnailData as object)
    ' This is a raw AA dump, comment this in or out on demand.
    '? "dumpThumbnailData() raw AA: "; formatJSON(thumbnailData);

   for each item in thumbnailData
		val = thumbnailData[item]
        ? "Thumbnail entry: " item
        ? " * bandwidth" val.bandwidth
        ? " * duration" val.duration
        ? " * height" val.height
        ? " * width" val.width
        ? " * vtiles" val.vtiles
        ? " * htiles" val.htiles
        ? ""
	end for
end sub

function largestThumbnailEntry(thumbnailData as object) as object
    entry = invalid
        for each item in thumbnailData
            val = thumbnailData[item]
            if entry = invalid
                entry = val
            else if val.width > entry.width
                entry = val
            end if
        end for
    return entry
end function


' We need a function that will return the max width (4096 pix) entries as
' there's a limit of max sized texture images in R2D2.
function thumbnailEntryForTextureMapLimits(thumbnailData as object) as object
    entry = invalid
    for each item in thumbnailData
            val = thumbnailData[item]
            if entry = invalid AND val.width * val.htiles < 4096
                entry = val
            else if val.width * val.htiles < 4096 AND val.width * val.htiles > entry.width * entry.htiles
                entry = val
            end if
    end for
#if thumbnailDebug
    if entry <> invalid
      ? "thumbnailEntryForTextureMapLimits(): selected data width = "; entry.width ; ", bandwidth = "; entry.bandwidth
    end if
#end if
    return entry
end function

' ********** Copyright 2019 Roku Corp.  All Rights Reserved. **********

' initCustomThumbnails
' Retrieve the thumbnail data

sub initCustomThumbnails(msg as object)
    m.customThumbnailData = msg.getData()

#IF thumbnailDebug
    dumpThumbnailData(m.customThumbnailData)
#ENDIF

    selectThumbnail()
    m.trickInterval = m.selectedThumbnailData[0].duration / (m.selectedThumbnailData[0].htiles * m.selectedThumbnailData[0].vtiles)
    initPosterSizes()
    initTranslatePosters()
end sub

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

    m.arrayPosters[0].loadwidth = m.POSTER_WIDTH * m.selectedThumbnailData[0].htiles
    m.arrayPosters[0].loadheight = m.POSTER_HEIGHT * m.selectedThumbnailData[0].vtiles

    m.arrayPosters[1].loadwidth = m.POSTER_WIDTH * m.selectedThumbnailData[0].htiles
    m.arrayPosters[1].loadheight = m.POSTER_HEIGHT * m.selectedThumbnailData[0].vtiles

    m.arrayPosters[2].loadwidth = m.POSTER_WIDTH_CENTER * m.selectedThumbnailData[0].htiles
    m.arrayPosters[2].loadheight = m.POSTER_HEIGHT_CENTER * m.selectedThumbnailData[0].vtiles

    m.arrayPosters[3].loadwidth = m.POSTER_WIDTH * m.selectedThumbnailData[0].htiles
    m.arrayPosters[3].loadheight = m.POSTER_HEIGHT * m.selectedThumbnailData[0].vtiles

    m.arrayPosters[4].loadwidth = m.POSTER_WIDTH * m.selectedThumbnailData[0].htiles
    m.arrayPosters[4].loadheight = m.POSTER_HEIGHT * m.selectedThumbnailData[0].vtiles
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

' Renders all the thumbnail posters. Each thumbnail poster will render their thumbnail based
' on the "current" video position, meaning that all thumbnails besides the middle thumbnail
' (the current thumbnail) will be offset by the trick interval, depending on how many thumbnails
' are present on screen.
sub renderPosters(position as double)
    if m.selectedThumbnailData <> invalid
        renderPoster(position - (m.trickInterval * 2), 0)
        renderPoster(position - m.trickInterval, 1)
        renderPoster(position, 2)
        renderPoster(position + m.trickInterval, 3)
        renderPoster(position + (m.trickInterval * 2), 4)
    end if
end sub

' Renders one poster at the specified poster index. This poster will populate the thumbnail
' that corresponds to the position passed into this function. If the discontinuity or sprite
' index are not found (returns a -1), then we do not give it a thumbnail poster to render
' and is left empty.
sub renderPoster(position as double, arrayPosterIndex as integer)
    discontinuityIndex = getDiscontinuityIndex(position)
    if discontinuityIndex <> -1
        spriteIndex = getSpriteIndex(position, discontinuityIndex)
        if spriteIndex <> -1
            rowColumnIndexes = getRowColumnIndexes(position, discontinuityIndex, spriteIndex)
            rowIndex = rowColumnIndexes.rowIndex
            columnIndex = rowColumnIndexes.columnIndex

            posterWidth = invalid
            posterHeight = invalid

            ' The center poster will have a slightly different width and height.
            if arrayPosterIndex <> 2
                posterWidth = m.POSTER_WIDTH
                posterHeight = m.POSTER_HEIGHT
            else
                posterWidth = m.POSTER_WIDTH_CENTER
                posterHeight = m.POSTER_HEIGHT_CENTER
            end if

            m.arrayPosters[arrayPosterIndex].clippingRect = [columnIndex * posterWidth, rowIndex * posterHeight, posterWidth, posterHeight]
            newTranslationX = m.arrayPosters[arrayPosterIndex].x - (posterWidth * columnIndex)
            newTranslationY = m.arrayPosters[arrayPosterIndex].y - (posterHeight * rowIndex)
            m.arrayPosters[arrayPosterIndex].translation = [newTranslationX, newTranslationY]
            m.arrayPosters[arrayPosterIndex].uri = m.selectedThumbnailData[discontinuityIndex].tiles[spriteIndex][0]
        else
            #IF thumbnailDebug
                ? "Thumbnail for poster index " + arrayPosterIndex.toStr() + " will be empty."
                ? "Position attempted to render poster: " + position.toStr()
            #ENDIF
            m.arrayPosters[arrayPosterIndex].uri = ""
        end if
    else
        #IF thumbnailDebug
            ? "Thumbnail for poster index " + arrayPosterIndex.toStr() + " will be empty."
            ? "Position attempted to render poster: " + position.toStr()
        #ENDIF
        m.arrayPosters[arrayPosterIndex].uri = ""
    end if
end sub

' Returns the discontinuity index based on the position being requested. This is
' needed in order to find the sprite sheet needed to get the proper thumbnail.
function getDiscontinuityIndex(position as double) as integer
    for i = 0 to m.selectedThumbnailData.count() - 1
        thumbnailData = m.selectedThumbnailData[i]
        if position >= thumbnailData.tiles[0][1] and position < thumbnailData.final_time
            #IF thumbnailDebug
                ? "Discontinuity index for position " + position.toStr() + ": " + i.toStr()
            #ENDIF
            return i
        end if
    end for
    #IF thumbnailDebug
        ? "Discontinuity index for position " + position.toStr() + " not found."
    #ENDIF
    return -1
end function

' Returns the sprite sheet index according to the position requested and the
' discontinuity index (calculated by getDiscontinuityIndex). This is needed in
' order to find the appropriate thumbnail tile, which means finding the row and
' column indexes within the sprite sheet based on position requested.
function getSpriteIndex(position as double, discontinuityIndex as integer) as integer
    if position < 0 or position > m.videoDuration then return -1

    for i = 0 to m.selectedThumbnailData[discontinuityIndex].tiles.count() - 1
        currentSpriteSheet = m.selectedThumbnailData[discontinuityIndex].tiles[i]
        nextSpriteSheet = invalid

        if (i + 1) < m.selectedThumbnailData[discontinuityIndex].tiles.count()
            nextSpriteSheet = m.selectedThumbnailData[discontinuityIndex].tiles[i + 1]
        end if

        currentSpriteSheetStartTime = currentSpriteSheet[1]
        if position >= currentSpriteSheetStartTime
            if nextSpriteSheet <> invalid
                nextSpriteSheetStartTime = nextSpriteSheet[1]
                if position < nextSpriteSheetStartTime
                    #IF thumbnailDebug
                        ? "Sprite index for position " + position.toStr() + ": " + i.toStr()
                    #ENDIF
                    return i
                end if
            else
                #IF thumbnailDebug
                    ? "Sprite index for position " + position.toStr() + ": " + i.toStr()
                #ENDIF
                return i
            end if
        else
            #IF thumbnailDebug
                ? "Sprite index for position " + position.toStr() + ": " + (i - 1).toStr()
            #ENDIF
            return i - 1
        end if
    end for
    #IF thumbnailDebug
        ? "Sprite index for position " + position.toStr() + " not found."
    #ENDIF
    return -1
end function

' Returns the row and column index corresponding to the position requested. We have to pass
' the discontinuity index and sprite index to know what poster to start looking up the row
' and column indexes from.
function getRowColumnIndexes(position as double, discontinuityIndex as integer, spriteIndex as integer) as object
    tileDuration = m.selectedThumbnailData[discontinuityIndex].duration / (m.selectedThumbnailData[discontinuityIndex].vtiles * m.selectedThumbnailData[discontinuityIndex].htiles)
    currentSpriteSheetStartTime = m.selectedThumbnailData[discontinuityIndex].tiles[spriteIndex][1]
    nextSpriteSheetStartTime = invalid

    rowIndex = 0
    columnIndex = 0
    exitForLoop = false

    for i = 0 to m.selectedThumbnailData[discontinuityIndex].vtiles - 1
        for j = 0 to m.selectedThumbnailData[discontinuityIndex].htiles - 1
            if position >= (currentSpriteSheetStartTime + (((i * m.selectedThumbnailData[discontinuityIndex].htiles) + j) * tileDuration))
                if position < (currentSpriteSheetStartTime + (((i * m.selectedThumbnailData[discontinuityIndex].htiles) + j + 1) * tileDuration))
                    rowIndex = i
                    columnIndex = j

                    #IF thumbnailDebug
                        ? "Row index for position " + position.toStr() + ": " + rowIndex.toStr()
                        ? "Column index for position " + position.toStr() + ": " + columnIndex.toStr()
                    #ENDIF
                    exitForLoop = true
                    exit for
                end if
            end if
        end for

        if exitForLoop
            exit for
        end if
    end for

    return {
        rowIndex: rowIndex
        columnIndex: columnIndex
    }
end function

' THUMBNAIL STREAM META FUNCTIONS

sub dumpThumbnailData(thumbnailData as object)
? "***** dumping thumbnail data"
   for each representation in thumbnailData
		thumbnailTiles = thumbnailData[representation]
        for each item in thumbnailTiles
            ? "Thumbnail entry: " representation
            ? item
        end for
	end for
? "***** finished dumping thumbnail data"
end sub

' We need a function that will return the max width (4096 pix) entries as
' there's a limit of max sized texture images in R2D2.
function thumbnailEntryForTextureMapLimits(thumbnailData as object) as object
    entry = invalid
    for each representation in thumbnailData
            thumbnailTiles = thumbnailData[representation]
            if entry = invalid AND thumbnailTiles[0].width < 2048 AND thumbnailTiles[0].htiles < 2048
                entry = thumbnailTiles
            else if thumbnailTiles[0].width < 2048 AND thumbnailTiles.htiles < 2048 AND thumbnailTiles[0].width * thumbnailTiles[0].htiles > entry.width * entry.htiles
                entry = thumbnailTiles
            end if
    end for
#IF thumbnailDebug
    if entry <> invalid
      ? "thumbnailEntryForTextureMapLimits(): selected data width = "; entry[0].width ; ", bandwidth = "; entry[0].bandwidth
    end if
#ENDIF
    return entry
end function

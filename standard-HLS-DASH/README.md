# CustomTrickplayThumbnails

This is a sample showing how to read DASH or HLS thumbnail streams and use these in a custom trickplaybar implementation.

Note that this depends on the latest 9.3 RokuOS release.

## Configuration

Change any test stream URL values in the manifest file directly.

Initially, the developer will have to host their own .mpd or .m3u8 files, a sample .m3u8 playlist is provided,
but it has to be hosted by the developer, please modify the manifest to point to your http server.

## Video Node Thumbnail Tiles

The thumbnail data such as URLs and meta-data is received from the video node via the `thumbnailtiles` field. The top level returns back an associative array of entries, ex:

``` code
{
    0_16460: <Component: roAssociativeArray>
    410000000_16460: <Component: roAssociativeArray>
}
```

Each entry in this AA has metadata information about the thumbnail file set as well as an array of tile URLs:

``` code
<Component: roAssociativeArray> =
{
    bandwidth: 16460
    duration: 210
    height: 180
    htiles: 5
    tiles: <Component: roArray>
    vtiles: 2
    width: 320
}
```

The array in turn has URL entries for the tiled arrays:

``` code
<Component: roArray> =
[
    "http://192.168.44.114:8888/sampleHlsPlaylist/5x2_640x360/thumb-tile-5x2-1.jpg"
    0
    ""
]

```

The first entry is the URL to the tiled file, the second entry is the tile starting offset (double value in seconds), and the third value is the tile format where "" is jpeg and "bif" is a BIF file.

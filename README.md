# trickplay-sample-channels
This repo introduces 4 samples that uses BIF/thumbnails during VOD trick play:
* Simple video with BIF support, no ads
* Simple video with custom UI and custom trick play support, no ads
* Native UI and BIF trick play support, with server stitched ads
* Custom UI and custom trick play support, with server stitched ads

For channels that use the Roku native video player UI, BIF is the recommended format for trick play thumbnails. More information on BIF can be found at the Roku SDK [Trick Mode Suppport](https://sdkdocs.roku.com/display/sdkdoc/Trick+Mode+Support) page.

The custom player UI mimics the Roku native player UI but with some small changes. The more interesting parts are the thumbnails and trick play logic, but the custom UI also includes a progress bar and a video buffering status loading bar.

The first sample [simplevideo-with-bif](/simplevideo-with-bif) uses BIF for trick play thumbnails. It is easy to use, just use biftool to create the BIF files, put them in a server, and add sdbifurl and hdbifurl to the contentnode given to Video node.

The second sample [simplevideo-with-jpeg](/simplevideo-with-jpeg) has a different approach to trick play thumbnails. It uses JPEG files for thumbnails, the thumbnails are generated using the script [gen-thumbs.sh](/scripts/gen-thumbs.sh) and extracted at constant intervals. The sample implements a custom player UI with a group of 5 Posters as thumbnails, it expects thumbnails generated at 5 second intervals.

The third sample [RAFSSAI-with-bif](/RAFSSAI-with-bif) also uses BIF for trick play thumbnails. In this sample, some trick play thumbnails have ads in them.

The fourth sample [RAFSSAI-with-jpeg](/RAF-SSAI-with-jpeg) has a different approach to trick play thumbnails. It uses JPEG files for thumbnails, the thumbnails are generated using the script [gen-thumbs.sh](/scripts/gen-thumbs.sh) and extracted at constant intervals. The sample implements a custom player UI with a group of 5 Posters as thumbnails, it expects thumbnails generated at 5 second intervals. The sample is aware of ad pods using metadata from RAF and ads are not displayed in the trick play thumbnails.

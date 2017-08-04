AV Sync
-----

## Concept

+ Muxer
    1. Calculate the ideal time duration of a frame
        > According to frame rate or sample rate

        ``` text
        AAC: 1024 samples in a frame, and sample rate = 44100Hz
        => druation = 1024 / 44100 = 0.02322 (sec) = 23.22 (ms)

        MP3: 1152 samples in a frame and sample rate = 44100Hz
        => duration = 1152 / 44100 = 0.02612 (sec) = 26.12 (ms)

        ```

    2. PTS is the accumulation of frame's duration. And follow the PTS value to mux A/V frames


+ Practice
    > 1. `DAC -> speaker` spend time and that will make a time delay
    > 1. Speaker displays with sample by sample. As the result, any sample can not be dropped.
    >     > Human can heart the defference which loss a sample or not.
    > 1. Fine tune the displaying speed of video (even dropping video frames) to sync audio.

    - ffmpeg case
        a. A audio packet may involve multi-frames
            > Need to re-calculate duration for the target frame.

            ```
              PTS_packet 0                               PTS_packet 1
                    ^                                        ^
            --------|-------|------------------|-------------|---------->  time
                            v                  v
                        PTS_frame N         PTS_frame N+1
                    |---numSamples/sampleRate->|

            PTS_frame N+1 = PTS_packet 0 + numSamples/sampleRate

            ```

        b. Data between `PTS_frame N` and `PTS_frame N+1` will push to DAC buffer. <br\>
            As the result, real audio PTS should reference the usage of DAC buffer
            > The goal is to get the timestamp of Speaker output

            ```
            real audio PTS = "PTS_frame N+1" - (Remain size in DAC buffer)/(sample rate)
            ```

        c. When Vidoe display, refers the `real audio PTS`




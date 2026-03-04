package com.myradio

data class RadioStation(
    val id: Int,
    val name: String,
    val streamUrl: String,
    val description: String
)

val RADIO_STATIONS = mutableListOf(
    RadioStation(
        id = 1,
        name = "BTV Radio",
        streamUrl = "https://cdn.bweb.bg/radio/btv-radio.mp3",
        description = "bTV Radio"
    ),
    RadioStation(
        id = 2,
        name = "Nova Play",
        streamUrl = "https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO_NOVAAAC_H.aac",
        description = "Nova Play"
    ),
    RadioStation(
        id = 3,
        name = "Horizont (BNR)",
        streamUrl = "https://lb-hls.cdn.bg/2032/fls/Horizont.stream/playlist.m3u8",
        description = "Bulgarian National Radio – Horizont"
    ),
    RadioStation(
        id = 4,
        name = "Hristo Botev (BNR)",
        streamUrl = "https://lb-hls.cdn.bg/2032/fls/HrBotev.stream/playlist.m3u8",
        description = "Bulgarian National Radio – Hristo Botev"
    )
)

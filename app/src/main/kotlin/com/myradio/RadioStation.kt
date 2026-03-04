package com.myradio

data class RadioStation(
    val id: Int,
    val name: String,
    val streamUrl: String,
    val description: String
)

val RADIO_STATIONS = listOf(
    RadioStation(
        id = 1,
        name = "BTV Radio",
        streamUrl = "https://stream.btvradio.bg/btvradio.mp3",
        description = "bTV Radio"
    ),
    RadioStation(
        id = 2,
        name = "Nova Play",
        streamUrl = "https://stream.nova.bg/novaplay.mp3",
        description = "Nova Play"
    ),
    RadioStation(
        id = 3,
        name = "Horizont (BNR)",
        streamUrl = "https://icecast.bgnc.net/horizont.mp3",
        description = "Bulgarian National Radio – Horizont"
    ),
    RadioStation(
        id = 4,
        name = "Hristo Botev (BNR)",
        streamUrl = "https://icecast.bgnc.net/hristobotev.mp3",
        description = "Bulgarian National Radio – Hristo Botev"
    )
)

import Foundation

struct RadioStation: Identifiable, Equatable {
    let id: Int
    let name: String
    let streamUrl: String
    let description: String
}

let hardcodedStations: [RadioStation] = [
    RadioStation(id: 1, name: "BTV Radio",      streamUrl: "https://cdn.bweb.bg/radio/btv-radio.mp3",                                                         description: "bTV Radio"),
    RadioStation(id: 2, name: "Nova News",       streamUrl: "https://radio.nova.bg/novanews.aac",                                                              description: "Nova News Radio – 95.7 FM"),
    RadioStation(id: 3, name: "Horizont (BNR)",  streamUrl: "https://lb-hls.cdn.bg/2032/fls/Horizont.stream/playlist.m3u8",                                    description: "Bulgarian National Radio – Horizont"),
    RadioStation(id: 4, name: "Hristo Botev (BNR)", streamUrl: "https://lb-hls.cdn.bg/2032/fls/HrBotev.stream/playlist.m3u8",                                 description: "Bulgarian National Radio – Hristo Botev"),
    RadioStation(id: 5, name: "Nova Play",       streamUrl: "https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO_NOVAAAC_H.aac",           description: "Nova Play"),
]

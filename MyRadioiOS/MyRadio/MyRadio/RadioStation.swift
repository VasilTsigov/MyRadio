import Foundation

struct RadioStation: Identifiable, Equatable {
    let id: Int
    let name: String
    let streamUrl: String
    let description: String
}

let hardcodedStations: [RadioStation] = [
    RadioStation(id: 1, name: "BTV Radio",         streamUrl: "https://cdn.bweb.bg/radio/btv-radio.mp3",                                                        description: "bTV Radio"),
    RadioStation(id: 2, name: "Nova News",          streamUrl: "https://radio.nova.bg/novanews.aac",                                                             description: "Nova News – 95.7 FM"),
    RadioStation(id: 3, name: "BG Radio",           streamUrl: "http://stream.radioreklama.bg/bgradio128",                                                        description: "BG Radio – 104.2 FM"),
    RadioStation(id: 4, name: "Horizont (BNR)",     streamUrl: "https://lb-hls.cdn.bg/2032/fls/Horizont.stream/playlist.m3u8",                                      description: "БНР Хоризонт"),
    RadioStation(id: 5, name: "Hristo Botev (BNR)", streamUrl: "https://lb-hls.cdn.bg/2032/fls/HrBotev.stream/playlist.m3u8",                                    description: "БНР Христо Ботев"),
    RadioStation(id: 6, name: "Nova Play",          streamUrl: "https://playerservices.streamtheworld.com/api/livestream-redirect/RADIO_NOVAAAC_H.aac",          description: "Nova Play"),
    RadioStation(id: 7, name: "Energy NRJ",         streamUrl: "http://play.global.audio/nrj128",                                                                 description: "Energy NRJ Bulgaria"),
    RadioStation(id: 8, name: "Tangra Mega Rock",   streamUrl: "http://stream-bg-01.radiotangra.com:8000/Tangra-high",                                            description: "Tangra Mega Rock"),
    RadioStation(id: 9, name: "Radio Veselina",     streamUrl: "https://bss1.neterra.tv/veselina/veselina.m3u8",                                                  description: "Радио Веселина"),
    RadioStation(id: 10, name: "Radio 1",            streamUrl: "http://stream.radioreklama.bg/radio164",                                                             description: "Радио 1 – 91.9 FM"),
    RadioStation(id: 11, name: "Radio 1 Rock",       streamUrl: "http://play.global.audio/radio1rockhi.aac",                                                          description: "Radio 1 Rock"),
]

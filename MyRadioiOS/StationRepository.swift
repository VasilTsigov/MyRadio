import Foundation

/// Fetches additional radio stations from the Radio Browser API.
/// Equivalent to StationRepository on Android.
actor StationRepository {

    static let shared = StationRepository()
    private init() {}

    func fetchNearbyStations(existing: [RadioStation]) async -> [RadioStation] {
        let countryCode = Locale.current.region?.identifier ?? "BG"
        let urlString = "https://all.api.radio-browser.info/json/stations/search"
            + "?countrycode=\(countryCode)&hidebroken=true&order=votes&reverse=true&limit=30"

        guard let url = URL(string: urlString) else { return [] }

        do {
            var request = URLRequest(url: url, timeoutInterval: 10)
            request.setValue("MyRadio/1.0", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { return [] }

            let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
            return parseStations(json, existing: existing)
        } catch {
            print("StationRepository error: \(error)")
            return []
        }
    }

    private func parseStations(_ json: [[String: Any]], existing: [RadioStation]) -> [RadioStation] {
        var existingNames = Set(existing.map { $0.name.lowercased() })
        var existingUrls  = Set(existing.map { $0.streamUrl })
        var result: [RadioStation] = []
        var nextId = 1000

        for obj in json {
            let name = (obj["name"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            let url  = (obj["url_resolved"] as? String ?? "").trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty, !url.isEmpty else { continue }
            guard !existingNames.contains(name.lowercased()) else { continue }
            guard !existingUrls.contains(url) else { continue }

            existingNames.insert(name.lowercased())
            existingUrls.insert(url)

            let country = obj["country"] as? String ?? ""
            let tags    = obj["tags"]    as? String ?? ""
            result.append(RadioStation(
                id: nextId,
                name: name,
                streamUrl: url,
                description: country.isEmpty ? tags : country
            ))
            nextId += 1
        }
        return result
    }
}

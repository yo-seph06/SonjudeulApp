import Foundation
import MapKit
import CoreLocation

/// 검색 결과 한 건. 최근 검색 기록으로도 저장한다.
struct PlaceResult: Identifiable, Codable, Equatable {
    var id = UUID()
    let title: String
    let roadAddress: String?
    let jibunAddress: String?
    let latitude: Double
    let longitude: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    /// 제목이 주소 그대로면 장소명이 아니다
    var placeName: String? {
        title == roadAddress || title == jibunAddress ? nil : title
    }
}

/// 좌표를 바꾼 주소. 카카오는 도로명·지번을 모두 주고, 애플 지도는 한 가지 주소만 준다.
struct ResolvedAddress: Equatable {
    var roadAddress: String?
    var jibunAddress: String?
    var buildingName: String?

    var primary: String? { roadAddress ?? jibunAddress }
}

enum PlaceSearchError: Error {
    case requestFailed
}

/// 카카오 로컬 API 키(Info.plist의 KakaoRestAPIKey)가 있으면 카카오로, 없거나 실패하면 애플 지도로
/// 주소·장소를 검색하고 좌표를 주소로 바꾼다. 키는 Config/Secrets.xcconfig에서 넣는다.
struct PlaceSearchService {
    static let shared = PlaceSearchService()

    private let kakaoKey: String?

    init(bundle: Bundle = .main) {
        let key = (bundle.object(forInfoDictionaryKey: "KakaoRestAPIKey") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if let key, !key.isEmpty, !key.hasPrefix("$(") {
            kakaoKey = key
        } else {
            kakaoKey = nil
        }
    }

    // MARK: - 검색

    func search(_ query: String, near center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        if kakaoKey != nil, let results = try? await kakaoSearch(query, near: center) {
            return results
        }
        return try await appleSearch(query, near: center)
    }

    func reverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> ResolvedAddress? {
        if kakaoKey != nil, let resolved = try? await kakaoReverseGeocode(coordinate) {
            return resolved
        }
        return try await appleReverseGeocode(coordinate)
    }

    // MARK: - 카카오 로컬 API

    private struct KakaoResponse<Document: Decodable>: Decodable {
        let documents: [Document]
    }

    private struct KakaoAddressDocument: Decodable {
        struct Road: Decodable {
            let address_name: String
            let building_name: String?
        }
        struct Jibun: Decodable {
            let address_name: String
        }
        let address_name: String
        let x: String
        let y: String
        let address: Jibun?
        let road_address: Road?
    }

    private struct KakaoKeywordDocument: Decodable {
        let place_name: String
        let address_name: String
        let road_address_name: String
        let x: String
        let y: String
    }

    private struct KakaoCoordDocument: Decodable {
        struct Road: Decodable {
            let address_name: String
            let building_name: String?
        }
        struct Jibun: Decodable {
            let address_name: String
        }
        let road_address: Road?
        let address: Jibun?
    }

    private func kakaoRequest<T: Decodable>(_ path: String, _ items: [URLQueryItem]) async throws -> T {
        guard let kakaoKey else { throw PlaceSearchError.requestFailed }
        var components = URLComponents(string: "https://dapi.kakao.com\(path)")!
        components.queryItems = items
        var request = URLRequest(url: components.url!)
        request.setValue("KakaoAK \(kakaoKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw PlaceSearchError.requestFailed }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func kakaoSearch(_ query: String, near center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        // 주소(도로명·지번) 검색과 장소(건물명·상호) 검색을 함께 돌려 주소 결과를 앞에 둔다
        async let addressResponse: KakaoResponse<KakaoAddressDocument> = kakaoRequest(
            "/v2/local/search/address.json",
            [URLQueryItem(name: "query", value: query), URLQueryItem(name: "size", value: "10")]
        )
        async let keywordResponse: KakaoResponse<KakaoKeywordDocument> = kakaoRequest(
            "/v2/local/search/keyword.json",
            [URLQueryItem(name: "query", value: query),
             URLQueryItem(name: "x", value: String(center.longitude)),
             URLQueryItem(name: "y", value: String(center.latitude)),
             URLQueryItem(name: "size", value: "15")]
        )
        let addresses = (try? await addressResponse.documents) ?? []
        let keywords = (try? await keywordResponse.documents) ?? []

        var results: [PlaceResult] = addresses.compactMap { doc in
            guard let lat = Double(doc.y), let lng = Double(doc.x) else { return nil }
            let road = doc.road_address?.address_name
            return PlaceResult(title: road ?? doc.address_name, roadAddress: road,
                               jibunAddress: doc.address?.address_name ?? doc.address_name,
                               latitude: lat, longitude: lng)
        }
        results += keywords.compactMap { doc in
            guard let lat = Double(doc.y), let lng = Double(doc.x) else { return nil }
            return PlaceResult(title: doc.place_name,
                               roadAddress: doc.road_address_name.isEmpty ? nil : doc.road_address_name,
                               jibunAddress: doc.address_name.isEmpty ? nil : doc.address_name,
                               latitude: lat, longitude: lng)
        }
        return results
    }

    private func kakaoReverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> ResolvedAddress? {
        let response: KakaoResponse<KakaoCoordDocument> = try await kakaoRequest(
            "/v2/local/geo/coord2address.json",
            [URLQueryItem(name: "x", value: String(coordinate.longitude)),
             URLQueryItem(name: "y", value: String(coordinate.latitude))]
        )
        guard let doc = response.documents.first else { return nil }
        let building = doc.road_address?.building_name
        return ResolvedAddress(roadAddress: doc.road_address?.address_name,
                               jibunAddress: doc.address?.address_name,
                               buildingName: (building?.isEmpty ?? true) ? nil : building)
    }

    // MARK: - 애플 지도 (키가 없을 때)

    private func appleSearch(_ query: String, near center: CLLocationCoordinate2D) async throws -> [PlaceResult] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = [.address, .pointOfInterest]
        request.region = MKCoordinateRegion(center: center, latitudinalMeters: 50_000, longitudinalMeters: 50_000)
        do {
            let items = try await MKLocalSearch(request: request).start().mapItems
            return items.map { item in
                let address = Self.formatAddress(item.placemark)
                return PlaceResult(title: item.name ?? address ?? query, roadAddress: address, jibunAddress: nil,
                                   latitude: item.placemark.coordinate.latitude,
                                   longitude: item.placemark.coordinate.longitude)
            }
        } catch let error as MKError where error.code == .placemarkNotFound {
            return []
        } catch {
            throw PlaceSearchError.requestFailed
        }
    }

    private func appleReverseGeocode(_ coordinate: CLLocationCoordinate2D) async throws -> ResolvedAddress? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ko_KR"))
        guard let placemark = placemarks.first, let address = Self.formatAddress(placemark) else { return nil }
        return ResolvedAddress(roadAddress: address, jibunAddress: nil, buildingName: nil)
    }

    /// 예: 서울특별시 중구 세종대로 110
    static func formatAddress(_ placemark: CLPlacemark) -> String? {
        var parts: [String] = []
        for part in [placemark.administrativeArea, placemark.locality, placemark.subLocality,
                     placemark.thoroughfare, placemark.subThoroughfare] {
            guard let part = part?.trimmingCharacters(in: .whitespaces), !part.isEmpty,
                  !parts.contains(part) else { continue }
            parts.append(part)
        }
        if placemark.thoroughfare == nil, let name = placemark.name, !name.isEmpty, !parts.contains(name) {
            parts.append(name)
        }
        let address = parts.joined(separator: " ")
        return address.isEmpty ? nil : address
    }
}

/// 최근 검색한 위치 (이 기기에만 최대 5개 저장)
enum RecentPlaceStore {
    private static let key = "sonjudeul_recent_places"
    private static let limit = 5

    static func load() -> [PlaceResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let places = try? JSONDecoder().decode([PlaceResult].self, from: data) else { return [] }
        return places
    }

    static func add(_ place: PlaceResult) {
        var places = load().filter { !($0.title == place.title && $0.roadAddress == place.roadAddress) }
        places.insert(place, at: 0)
        save(Array(places.prefix(limit)))
    }

    static func remove(_ place: PlaceResult) {
        save(load().filter { $0.id != place.id })
    }

    static func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func save(_ places: [PlaceResult]) {
        if let data = try? JSONEncoder().encode(places) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}

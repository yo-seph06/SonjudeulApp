import SwiftUI
import MapKit
import CoreLocation

/// 부모님 위치를 지도에서 검색하거나 직접 골라 주소와 위도·경도를 함께 돌려준다.
/// 지도 가운데 핀이 가리키는 곳이 선택 위치이고, 지도를 움직이면 주소를 다시 가져온다.
struct ParentLocationPickerView: View {
    let initialLocation: ParentLocation?
    let onSelect: (ParentLocation) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var search = AddressSearchModel()
    @StateObject private var locator = CurrentLocationProvider()

    @State private var position: MapCameraPosition
    @State private var center: CLLocationCoordinate2D
    @State private var resolvedAddress: String?
    @State private var isResolving = false
    @State private var errorMessage: String?
    /// 검색으로 고른 위치. 지도가 그 자리에 머무는 동안은 검색 결과 주소를 유지한다.
    @State private var searchedCoordinate: CLLocationCoordinate2D?
    @State private var resolveTask: Task<Void, Never>?
    @FocusState private var searchFocused: Bool

    private static let defaultCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 서울시청

    init(initialLocation: ParentLocation?, onSelect: @escaping (ParentLocation) -> Void) {
        self.initialLocation = initialLocation
        self.onSelect = onSelect
        let start = initialLocation.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            ?? Self.defaultCenter
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: start, latitudinalMeters: 500, longitudinalMeters: 500)))
        _center = State(initialValue: start)
        _resolvedAddress = State(initialValue: initialLocation?.address)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                searchBar

                ZStack(alignment: .top) {
                    mapArea

                    if searchFocused && !search.results.isEmpty {
                        searchResults
                    }
                }

                bottomCard
            }
            .background(Color.sonjuBackground.ignoresSafeArea())
            .navigationTitle("부모님 위치 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.sonjuSecondary)
                }
            }
            .onAppear {
                if initialLocation == nil { resolveAddress(for: center) }
            }
            .onChange(of: locator.lastLocation) { _, location in
                guard let location else { return }
                moveCamera(to: location.coordinate)
            }
            .onChange(of: locator.errorMessage) { _, message in
                if let message { errorMessage = message }
            }
        }
    }

    // MARK: - 검색

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.sonjuSecondary)
            TextField("건물명, 도로명, 지번 주소로 검색", text: $search.query)
                .font(.sonjuBody)
                .focused($searchFocused)
                .submitLabel(.search)
                .onSubmit { searchFirstResult() }
            if !search.query.isEmpty {
                Button { search.query = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.sonjuSecondary)
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private var searchResults: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(search.results, id: \.self) { completion in
                    Button { select(completion) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(completion.title)
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuText)
                            if !completion.subtitle.isEmpty {
                                Text(completion.subtitle)
                                    .font(.sonjuCaption)
                                    .foregroundColor(.sonjuSecondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    Divider().background(Color.sonjuDivider)
                }
            }
        }
        .frame(maxHeight: 280)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        .padding(.horizontal, 16)
    }

    private func select(_ completion: MKLocalSearchCompletion) {
        searchFocused = false
        Task {
            do {
                let response = try await MKLocalSearch(request: MKLocalSearch.Request(completion: completion)).start()
                guard let item = response.mapItems.first else {
                    errorMessage = "검색한 위치를 찾지 못했어요. 다른 주소로 검색해 주세요."
                    return
                }
                apply(item, fallbackTitle: completion.title)
            } catch {
                errorMessage = "위치를 검색하지 못했어요. 인터넷 연결을 확인해 주세요."
            }
        }
    }

    private func searchFirstResult() {
        if let first = search.results.first {
            select(first)
            return
        }
        let query = search.query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        searchFocused = false
        Task {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query
            request.region = MKCoordinateRegion(center: center, latitudinalMeters: 50_000, longitudinalMeters: 50_000)
            if let item = try? await MKLocalSearch(request: request).start().mapItems.first {
                apply(item, fallbackTitle: query)
            } else {
                errorMessage = "검색 결과가 없어요. 건물명이나 도로명 주소로 다시 검색해 주세요."
            }
        }
    }

    /// 검색 결과는 건물명까지 붙여 주소로 쓰고, 지도 이동 후 역지오코딩으로 덮어쓰지 않는다.
    private func apply(_ item: MKMapItem, fallbackTitle: String) {
        let placemark = item.placemark
        var address = Self.formatAddress(placemark) ?? fallbackTitle
        if let name = item.name, !name.isEmpty, !address.contains(name) {
            address += " (\(name))"
        }
        resolveTask?.cancel()
        searchedCoordinate = placemark.coordinate
        resolvedAddress = address
        isResolving = false
        errorMessage = nil
        moveCamera(to: placemark.coordinate)
    }

    // MARK: - 지도

    private var mapArea: some View {
        MapReader { proxy in
            Map(position: $position) {
                UserAnnotation()
            }
            .mapControls {
                MapCompass()
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                center = context.region.center
                if let searched = searchedCoordinate, Self.distance(searched, center) < 15 {
                    return
                }
                searchedCoordinate = nil
                resolveAddress(for: center)
            }
            .onTapGesture { point in
                searchFocused = false
                if let coordinate = proxy.convert(point, from: .local) {
                    moveCamera(to: coordinate)
                }
            }
            .overlay {
                // 가운데 고정 핀: 핀 끝이 지도 중심을 가리키도록 위로 올린다
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white, Color.sonjuPrimary)
                    .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                    .offset(y: -20)
                    .allowsHitTesting(false)
            }
            .overlay(alignment: .bottomTrailing) {
                Button { locator.requestCurrentLocation() } label: {
                    Image(systemName: "location.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.sonjuPrimary)
                        .frame(width: 48, height: 48)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 2)
                }
                .accessibilityLabel("현재 위치로 이동")
                .padding(16)
            }
        }
    }

    private static func distance(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: a.latitude, longitude: a.longitude)
            .distance(from: CLLocation(latitude: b.latitude, longitude: b.longitude))
    }

    private func moveCamera(to coordinate: CLLocationCoordinate2D) {
        withAnimation {
            position = .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 400, longitudinalMeters: 400))
        }
    }

    private func resolveAddress(for coordinate: CLLocationCoordinate2D) {
        resolveTask?.cancel()
        isResolving = true
        errorMessage = nil
        resolveTask = Task {
            // 지도를 연달아 움직일 때 요청이 몰리지 않도록 잠깐 기다린다
            try? await Task.sleep(nanoseconds: 300_000_000)
            guard !Task.isCancelled else { return }
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location, preferredLocale: Locale(identifier: "ko_KR"))
            guard !Task.isCancelled else { return }
            isResolving = false
            if let placemark = placemarks?.first, let address = Self.formatAddress(placemark) {
                resolvedAddress = address
            } else {
                resolvedAddress = nil
                errorMessage = "이 위치의 주소를 가져오지 못했어요. 지도를 조금 움직이거나 주소로 검색해 주세요."
            }
        }
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

    // MARK: - 하단 카드

    private var bottomCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 20))
                    .foregroundColor(.sonjuPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("선택한 위치")
                        .font(.sonjuCaption)
                        .foregroundColor(.sonjuSecondary)
                    if isResolving {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("주소를 확인하는 중...")
                                .font(.sonjuBody)
                                .foregroundColor(.sonjuSecondary)
                        }
                    } else {
                        Text(resolvedAddress ?? "지도를 움직이거나 주소를 검색해 위치를 선택해 주세요")
                            .font(.sonjuBody)
                            .foregroundColor(resolvedAddress == nil ? .sonjuSecondary : .sonjuText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.sonjuCaption)
                    .foregroundColor(.red)
            }

            AmberButton(title: "이 위치로 등록", disabled: !canConfirm) {
                guard let address = resolvedAddress else { return }
                let location = ParentLocation(address: address, latitude: center.latitude, longitude: center.longitude)
                guard location.isValid else {
                    errorMessage = "위치 정보를 가져오지 못했어요. 다시 선택해 주세요."
                    return
                }
                onSelect(location)
                dismiss()
            }
        }
        .padding(20)
        .background(Color.white.ignoresSafeArea(edges: .bottom))
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: -2)
    }

    private var canConfirm: Bool {
        !isResolving && !(resolvedAddress?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}

// MARK: - 주소 자동완성

final class AddressSearchModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var query = "" {
        didSet {
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                results = []
            } else {
                completer.queryFragment = trimmed
            }
        }
    }
    @Published private(set) var results: [MKLocalSearchCompletion] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? [] : completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        results = []
    }
}

// MARK: - 현재 위치 (권한을 거부해도 검색·지도 선택은 그대로 쓸 수 있다)

final class CurrentLocationProvider: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var lastLocation: CLLocation?
    @Published var errorMessage: String?

    private let manager = CLLocationManager()
    private var wantsLocation = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestCurrentLocation() {
        errorMessage = nil
        wantsLocation = true
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        default:
            wantsLocation = false
            errorMessage = "위치 권한이 꺼져 있어요. 주소 검색이나 지도에서 직접 위치를 선택해 주세요. (설정 > 손주들 > 위치에서 켤 수 있어요)"
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard wantsLocation else { return }
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            wantsLocation = false
            errorMessage = "위치 권한이 거부되었어요. 주소 검색이나 지도에서 직접 위치를 선택해 주세요."
        default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        wantsLocation = false
        if let location = locations.last {
            lastLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        wantsLocation = false
        errorMessage = "현재 위치를 가져오지 못했어요. 주소 검색이나 지도에서 직접 선택해 주세요."
    }
}

#Preview {
    ParentLocationPickerView(initialLocation: nil) { _ in }
}

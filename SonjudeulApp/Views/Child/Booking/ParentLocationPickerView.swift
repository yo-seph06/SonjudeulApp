import SwiftUI
import MapKit
import CoreLocation

/// 카카오맵처럼 지도를 화면 가득 띄우고, 가운데 고정 핀이 가리키는 곳을 부모님 위치로 고른다.
/// 지도 이동이 끝나면 그 좌표의 도로명·지번 주소를 가져오고, 등록 시 주소와 위도·경도를 함께 돌려준다.
struct ParentLocationPickerView: View {
    let initialLocation: ParentLocation?
    let initialDetail: String
    let onSelect: (ParentLocation, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var search = PlaceSearchModel()
    @StateObject private var locator = CurrentLocationProvider()

    @State private var position: MapCameraPosition
    @State private var center: CLLocationCoordinate2D
    @State private var resolved: ResolvedAddress?
    @State private var placeName: String?
    @State private var detail: String
    @State private var isResolving = false
    @State private var isMoving = false
    @State private var errorMessage: String?
    /// 검색으로 고른 위치. 지도가 그 자리에 머무는 동안은 검색 결과 주소를 유지한다.
    @State private var searchedCoordinate: CLLocationCoordinate2D?
    @State private var resolveTask: Task<Void, Never>?
    @FocusState private var searchFocused: Bool
    @FocusState private var detailFocused: Bool

    private static let defaultCenter = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 서울시청

    init(initialLocation: ParentLocation?, initialDetail: String = "",
         onSelect: @escaping (ParentLocation, String) -> Void) {
        self.initialLocation = initialLocation
        self.initialDetail = initialDetail
        self.onSelect = onSelect
        let start = initialLocation.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
            ?? Self.defaultCenter
        _position = State(initialValue: .region(MKCoordinateRegion(
            center: start, latitudinalMeters: 400, longitudinalMeters: 400)))
        _center = State(initialValue: start)
        _detail = State(initialValue: initialDetail)
        if let initialLocation {
            _resolved = State(initialValue: ResolvedAddress(
                roadAddress: initialLocation.roadAddress ?? initialLocation.address,
                jibunAddress: initialLocation.jibunAddress))
            _searchedCoordinate = State(initialValue: start)
        }
    }

    var body: some View {
        ZStack {
            mapArea
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                if searchFocused {
                    searchPanel
                } else {
                    Spacer()
                    currentLocationButton
                    bottomPanel
                }
            }
        }
        .background(Color.sonjuBackground)
        .onAppear {
            search.center = center
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

    // MARK: - 상단 검색창

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                if searchFocused {
                    searchFocused = false
                } else {
                    dismiss()
                }
            } label: {
                Image(systemName: searchFocused ? "chevron.left" : "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.sonjuText)
                    .frame(width: 48, height: 48)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
            }
            .accessibilityLabel(searchFocused ? "검색 닫기" : "닫기")

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.sonjuPrimary)
                TextField("주소, 건물명, 장소 검색", text: $search.query)
                    .font(.sonjuBody)
                    .focused($searchFocused)
                    .submitLabel(.search)
                    .onSubmit { search.searchNow() }
                if !search.query.isEmpty {
                    Button { search.query = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.sonjuSecondary.opacity(0.6))
                    }
                }
            }
            .padding(.horizontal, 18)
            .frame(height: 48)
            .background(Color.white)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(searchFocused ? Color.sonjuPrimary : Color.clear, lineWidth: 1.5))
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, searchFocused ? 8 : 0)
        .background {
            if searchFocused { Color.white.ignoresSafeArea(edges: .top) }
        }
    }

    // MARK: - 검색 결과 / 최근 검색

    private var searchPanel: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if search.query.trimmingCharacters(in: .whitespaces).isEmpty {
                    if search.recents.isEmpty {
                        emptyMessage("주소, 건물명, 장소 이름으로 검색해 주세요")
                    } else {
                        HStack {
                            Text("최근 검색")
                                .font(.sonjuCaption.weight(.semibold))
                                .foregroundColor(.sonjuSecondary)
                            Spacer()
                            Button("전체 삭제") { search.clearRecents() }
                                .font(.sonjuCaption)
                                .foregroundColor(.sonjuSecondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        ForEach(search.recents) { place in
                            resultRow(place, icon: "clock.arrow.circlepath") {
                                search.removeRecent(place)
                            }
                        }
                    }
                } else if search.isSearching && search.results.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .padding(.vertical, 40)
                } else if let message = search.errorMessage {
                    emptyMessage(message)
                } else if search.results.isEmpty && search.hasSearched {
                    emptyMessage("검색 결과가 없어요.\n도로명, 지번, 건물명으로 다시 검색해 주세요.")
                } else {
                    ForEach(search.results) { place in
                        resultRow(place, icon: "mappin.circle.fill", onRemove: nil)
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
    }

    private func resultRow(_ place: PlaceResult, icon: String, onRemove: (() -> Void)?) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Button { select(place) } label: {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(onRemove == nil ? .sonjuPrimary : .sonjuSecondary)
                        .frame(width: 24)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(place.title)
                            .font(.sonjuBody.weight(.semibold))
                            .foregroundColor(.sonjuText)
                        if let road = place.roadAddress, road != place.title {
                            addressLine(tag: "도로명", text: road)
                        }
                        if let jibun = place.jibunAddress, jibun != place.title {
                            addressLine(tag: "지번", text: jibun)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if let onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.sonjuSecondary)
                        .frame(width: 28, height: 28)
                }
                .accessibilityLabel("최근 검색에서 삭제")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Divider().background(Color.sonjuDivider).padding(.leading, 56)
        }
    }

    private func addressLine(tag: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(tag)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.sonjuSecondary)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.sonjuSecondary.opacity(0.4), lineWidth: 1))
            Text(text)
                .font(.sonjuCaption)
                .foregroundColor(.sonjuSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func emptyMessage(_ text: String) -> some View {
        Text(text)
            .font(.sonjuBody)
            .foregroundColor(.sonjuSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
    }

    private func select(_ place: PlaceResult) {
        searchFocused = false
        RecentPlaceStore.add(place)
        search.reloadRecents()
        resolveTask?.cancel()
        isResolving = false
        errorMessage = nil
        searchedCoordinate = place.coordinate
        resolved = ResolvedAddress(roadAddress: place.roadAddress, jibunAddress: place.jibunAddress)
        placeName = place.placeName
        moveCamera(to: place.coordinate)
    }

    // MARK: - 지도

    private var mapArea: some View {
        Map(position: $position) {
            UserAnnotation()
        }
        .mapControlVisibility(.hidden)
        .onMapCameraChange(frequency: .continuous) { _ in
            if !isMoving { isMoving = true }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            isMoving = false
            center = context.region.center
            search.center = center
            if let searched = searchedCoordinate, Self.distance(searched, center) < 15 {
                return
            }
            searchedCoordinate = nil
            placeName = nil
            resolveAddress(for: center)
        }
        .overlay { centerPin }
    }

    /// 가운데 고정 핀. 지도를 움직이는 동안 살짝 들어 올려 위치를 맞추는 느낌을 준다.
    private var centerPin: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(isMoving ? 0.12 : 0.25))
                .frame(width: isMoving ? 10 : 14, height: isMoving ? 4 : 6)

            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(Color.sonjuPrimary)
                        .frame(width: 36, height: 36)
                    Circle()
                        .fill(Color.white)
                        .frame(width: 13, height: 13)
                }
                .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
                Rectangle()
                    .fill(Color.sonjuDeep)
                    .frame(width: 3, height: 14)
            }
            // 핀 아래 끝이 지도 중심(그림자 위치)에 오도록 올린다
            .offset(y: -25 - (isMoving ? 10 : 0))
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isMoving)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var currentLocationButton: some View {
        HStack {
            Spacer()
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
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
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
            let address = try? await PlaceSearchService.shared.reverseGeocode(coordinate)
            guard !Task.isCancelled else { return }
            isResolving = false
            if let address, address.primary != nil {
                resolved = address
                placeName = address.buildingName
            } else {
                resolved = nil
                errorMessage = "이 위치의 주소를 가져오지 못했어요. 지도를 조금 움직이거나 주소로 검색해 주세요."
            }
        }
    }

    // MARK: - 하단 위치 정보 패널

    private var bottomPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Capsule()
                .fill(Color.sonjuDivider)
                .frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)

            if isResolving || isMoving {
                HStack(spacing: 10) {
                    ProgressView()
                    Text(isMoving ? "지도를 움직여 위치를 맞춰주세요" : "주소를 확인하는 중...")
                        .font(.sonjuBody)
                        .foregroundColor(.sonjuSecondary)
                }
                .frame(minHeight: 52, alignment: .leading)
            } else if let resolved, let primary = resolved.primary {
                VStack(alignment: .leading, spacing: 6) {
                    if let placeName {
                        Text(placeName)
                            .font(.sonjuCaption.weight(.semibold))
                            .foregroundColor(.sonjuPrimary)
                    }
                    Text(primary)
                        .font(.sonjuTitle)
                        .foregroundColor(.sonjuText)
                        .fixedSize(horizontal: false, vertical: true)
                    if let jibun = resolved.jibunAddress, resolved.roadAddress != nil, jibun != primary {
                        addressLine(tag: "지번", text: jibun)
                    }
                }
            } else {
                Text("지도를 움직이거나 주소를 검색해 위치를 선택해 주세요")
                    .font(.sonjuBody)
                    .foregroundColor(.sonjuSecondary)
                    .frame(minHeight: 52, alignment: .leading)
            }

            TextField("상세 주소 (예: 101동 1001호)", text: $detail)
                .font(.sonjuBody)
                .focused($detailFocused)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color.sonjuBackground)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(detailFocused ? Color.sonjuPrimary : Color.clear, lineWidth: 1.5))

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.circle.fill")
                    .font(.sonjuCaption)
                    .foregroundColor(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            AmberButton(title: "위치 등록 완료", disabled: !canConfirm) {
                confirm()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: -2)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private var canConfirm: Bool {
        !isResolving && !isMoving
            && !(resolved?.primary?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private func confirm() {
        guard let resolved, let primary = resolved.primary else { return }
        var address = primary
        if let placeName, !address.contains(placeName) {
            address += " (\(placeName))"
        }
        let location = ParentLocation(address: address, latitude: center.latitude, longitude: center.longitude,
                                      roadAddress: resolved.roadAddress, jibunAddress: resolved.jibunAddress)
        guard location.isValid else {
            errorMessage = "위치 정보를 가져오지 못했어요. 다시 선택해 주세요."
            return
        }
        onSelect(location, detail.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
    }
}

// MARK: - 검색 (입력이 멈추면 자동으로 검색)

@MainActor
final class PlaceSearchModel: ObservableObject {
    @Published var query = "" {
        didSet { scheduleSearch() }
    }
    @Published private(set) var results: [PlaceResult] = []
    @Published private(set) var recents: [PlaceResult] = RecentPlaceStore.load()
    @Published private(set) var isSearching = false
    @Published private(set) var hasSearched = false
    @Published private(set) var errorMessage: String?

    var center = CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
    private var task: Task<Void, Never>?

    func searchNow() {
        run(delay: 0)
    }

    func reloadRecents() { recents = RecentPlaceStore.load() }

    func removeRecent(_ place: PlaceResult) {
        RecentPlaceStore.remove(place)
        reloadRecents()
    }

    func clearRecents() {
        RecentPlaceStore.clear()
        reloadRecents()
    }

    private func scheduleSearch() {
        run(delay: 350_000_000)
    }

    private func run(delay: UInt64) {
        task?.cancel()
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            results = []
            hasSearched = false
            errorMessage = nil
            isSearching = false
            return
        }
        isSearching = true
        let center = center
        task = Task {
            if delay > 0 { try? await Task.sleep(nanoseconds: delay) }
            guard !Task.isCancelled else { return }
            do {
                let found = try await PlaceSearchService.shared.search(text, near: center)
                guard !Task.isCancelled else { return }
                results = found
                errorMessage = nil
            } catch {
                guard !Task.isCancelled else { return }
                results = []
                errorMessage = "위치를 검색하지 못했어요. 인터넷 연결을 확인해 주세요."
            }
            isSearching = false
            hasSearched = true
        }
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
    ParentLocationPickerView(initialLocation: nil) { _, _ in }
}

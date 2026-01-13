import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: BeautyStore

    @State private var currentMonth: Date = Date()

    @State private var selectedDay: Date? = nil
    @State private var isDayOverlayPresented: Bool = false

    @State private var showAddProductToDay: Bool = false
    @State private var showAddLookToDay: Bool = false
    @State private var pendingDayForAdd: Date? = nil

    private let calendar = Calendar.current

    private let cornerRadius: CGFloat = 18
    private let dotSize: CGFloat = 5

    private let floatingTabBarHeight: CGFloat = 70
    private let floatingTabBarOuterBottomPadding: CGFloat = 6
    private let floatingTabBarExtraSafeGap: CGFloat = 22

    private var scrollBottomPadding: CGFloat {
        floatingTabBarHeight + floatingTabBarOuterBottomPadding + floatingTabBarExtraSafeGap
    }

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            VStack(spacing: 0) {
                AppNavBar(title: "Calendar", onBack: nil, onAdd: nil)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        calendarBlock
                        todayBlock
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, scrollBottomPadding)
                }
            }

            if isDayOverlayPresented, let selectedDay {
                DayUsageOverlay(
                    date: selectedDay,
                    looks: store.looksForDay(selectedDay),
                    cosmetics: store.cosmeticsForDay(selectedDay),
                    catalogCosmetics: store.cosmetics,
                    onClose: { closeOverlay() },
                    onRemoveLook: { lookID in
                        store.removeLookFromDay(dayKey: store.dayKey(for: selectedDay), lookID: lookID)
                        if store.usageEntry(for: selectedDay) == nil { closeOverlay() }
                    },
                    onRemoveCosmetic: { cosmeticID in
                        store.removeCosmeticFromDay(dayKey: store.dayKey(for: selectedDay), cosmeticID: cosmeticID)
                        if store.usageEntry(for: selectedDay) == nil { closeOverlay() }
                    },
                    onAddProduct: {
                        pendingDayForAdd = selectedDay
                        isDayOverlayPresented = false
                        showAddProductToDay = true
                    },
                    onAddLook: {
                        pendingDayForAdd = selectedDay
                        isDayOverlayPresented = false
                        showAddLookToDay = true
                    }
                )
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .navigationDestination(isPresented: $showAddProductToDay) {
            if let date = pendingDayForAdd {
                AddProductToDayView(date: date) {
                    pendingDayForAdd = date
                    selectedDay = date
                    isDayOverlayPresented = true
                }
                .environmentObject(store)
                .navigationBarBackButtonHidden()
            }
        }
        .navigationDestination(isPresented: $showAddLookToDay) {
            if let date = pendingDayForAdd {
                AddLookToDayView(date: date) {
                    pendingDayForAdd = date
                    selectedDay = date
                    isDayOverlayPresented = true
                }
                .environmentObject(store)
                .navigationBarBackButtonHidden()
            }
        }
    }

    private var calendarBlock: some View {
        VStack(spacing: 12) {
            header
            weekdaysRow
            daysGrid
        }
        .padding(14)
        .background(AppColor.backgroundGray)
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColor.orange, lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private var header: some View {
        HStack {
            Text(monthTitle(currentMonth))
                .font(AppFont.make(size: 20, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))

            Spacer()

            Button { changeMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)

            Button { changeMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
    }

    private var weekdaysRow: some View {
        let symbols = weekdaySymbols()
        return HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s)
                    .font(AppFont.make(size: 20, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        let cells = buildMonthCells(for: currentMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)

        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(cells) { cell in
                dayCell(cell)
            }
        }
    }

    private func dayCell(_ cell: MonthCell) -> some View {
        let isToday = cell.date.map { calendar.isDateInToday($0) } ?? false
        let hasLook = cell.date.map { store.hasLookUsage(on: $0) } ?? false
        let hasCosmetics = cell.date.map { store.hasCosmeticsUsage(on: $0) } ?? false

        return VStack(spacing: 4) {
            HStack(spacing: 3) {
                if hasLook {
                    Circle().fill(AppColor.orange).frame(width: dotSize, height: dotSize)
                }
                if hasCosmetics {
                    Circle().fill(AppColor.blue).frame(width: dotSize, height: dotSize)
                }
            }
            .frame(height: dotSize)

            Text(cell.text)
                .font(AppFont.make(size: 13, weight: .regular))
                .foregroundStyle(cell.inCurrentMonth ? .white : .white.opacity(0.25))
                .overlay(alignment: .bottom) {
                    if isToday {
                        Rectangle()
                            .fill(AppColor.orange)
                            .frame(height: 2)
                            .offset(y: 4)
                    }
                }
        }
        .frame(height: 36)
        .contentShape(Rectangle())
        .onTapGesture {
            guard let date = cell.date, cell.inCurrentMonth else { return }
            selectedDay = date
            withAnimation(.easeOut(duration: 0.18)) {
                isDayOverlayPresented = true
            }
        }
    }

    private var todayBlock: some View {
        let looks = store.todaysLooks()
        let cosmetics = store.todaysCosmetics()

        return VStack(alignment: .leading, spacing: 14) {
            if store.hasAnyUsageToday {
                Text("Today:")
                    .font(AppFont.make(size: 22, weight: .bold))
                    .foregroundStyle(.white)

                if !looks.isEmpty {
                    Text("Looks")
                        .font(AppFont.make(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.orange)

                    ForEach(looks, id: \.id) { look in
                        LookRowCard(
                            cosmetics: store.cosmeticsForLook(look, limit: 3),
                            note: look.note,
                            onEdit: {},
                            onDelete: {}
                        )
                    }
                }

                if !cosmetics.isEmpty {
                    Text("Cosmetics")
                        .font(AppFont.make(size: 18, weight: .bold))
                        .foregroundStyle(AppColor.orange)

                    HStack(spacing: 12) {
                        ForEach(Array(cosmetics.prefix(3)), id: \.id) { item in
                            LookPreviewMiniCard(item: item)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func closeOverlay() {
        withAnimation(.easeOut(duration: 0.18)) {
            isDayOverlayPresented = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            selectedDay = nil
        }
    }

    private func changeMonth(_ delta: Int) {
        currentMonth = calendar.date(byAdding: .month, value: delta, to: currentMonth) ?? currentMonth
    }

    private func monthTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MMMM yyyy"
        return df.string(from: date)
    }

    private func weekdaySymbols() -> [String] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        let symbols = df.veryShortWeekdaySymbols ?? ["M","T","W","T","F","S","S"]
        let shift = (calendar.firstWeekday + 5) % 7
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private func buildMonthCells(for date: Date) -> [MonthCell] {
        guard
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
            let range = calendar.range(of: .day, in: .month, for: start)
        else { return [] }

        let firstWeekday = calendar.component(.weekday, from: start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7

        var cells: [MonthCell] = []

        for _ in 0..<leading {
            cells.append(MonthCell(date: nil, text: "", inCurrentMonth: false))
        }

        for day in range {
            let d = calendar.date(byAdding: .day, value: day - 1, to: start)
            cells.append(MonthCell(date: d, text: "\(day)", inCurrentMonth: true))
        }

        while cells.count % 7 != 0 {
            cells.append(MonthCell(date: nil, text: "", inCurrentMonth: false))
        }

        return cells
    }
}

struct MonthCell: Identifiable {
    let id = UUID()
    let date: Date?
    let text: String
    let inCurrentMonth: Bool
}

private struct DayUsageOverlay: View {
    let date: Date
    let looks: [Look]
    let cosmetics: [CosmeticItem]
    let catalogCosmetics: [CosmeticItem]
    
    let onClose: () -> Void
    let onRemoveLook: (UUID) -> Void
    let onRemoveCosmetic: (UUID) -> Void
    let onAddProduct: () -> Void
    let onAddLook: () -> Void

    private let corner: CGFloat = 18
    private let maxCardWidth: CGFloat = 360

    @State private var measuredContentHeight: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let maxHeight = geo.size.height * 0.8
            let cardHeight = min(measuredContentHeight, maxHeight)
            let canScroll = measuredContentHeight > maxHeight

            ZStack {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .onTapGesture { onClose() }

                ZStack(alignment: .topTrailing) {
                    ScrollView(showsIndicators: false) {
                        content
                            .background(
                                HeightMeasurer { h in
                                    if measuredContentHeight != h { measuredContentHeight = h }
                                }
                            )
                    }
                    .scrollDisabled(!canScroll)
                    .frame(width: maxCardWidth)
                    .frame(height: cardHeight)
                    .background(AppColor.backgroundGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(AppColor.orange, lineWidth: 1.5)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

                    closeButton
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, 16)
            }
            .animation(.easeOut(duration: 0.18), value: cardHeight)
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(dateTitle(date))
                .font(AppFont.make(size: 20, weight: .bold))
                .foregroundStyle(AppColor.orange)
                .padding(.top, 16)

            if !looks.isEmpty {
                ForEach(looks, id: \.id) { look in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(look.title)
                            .font(AppFont.make(size: 22, weight: .bold))
                            .foregroundStyle(.white)

                        LookRowCard(
                            cosmetics: cosmeticsForLook(look, limit: 3),
                            note: look.note,
                            onEdit: {},
                            onDelete: {}
                        )
                        .overlay(alignment: .topTrailing) {
                            Button { onRemoveLook(look.id) } label: {
                                Circle()
                                    .fill(AppColor.red)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    )
                            }
                            .buttonStyle(.plain)
                            .offset(x: 6, y: -6)
                        }
                    }
                }
            }

            if !cosmetics.isEmpty {
                let rows = cosmetics.chunked(into: 3)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(rows.indices, id: \.self) { idx in
                        HStack(spacing: 12) {
                            ForEach(rows[idx], id: \.id) { item in
                                OverlayMiniCosmeticCard(item: item) {
                                    onRemoveCosmetic(item.id)
                                }
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }

            HStack(spacing: 14) {
                Button(action: onAddProduct) {
                    Text("+ Product")
                        .font(AppFont.make(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .background(AppColor.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onAddLook) {
                    Text("+ Look")
                        .font(AppFont.make(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(height: 54)
                        .frame(maxWidth: .infinity)
                        .background(AppColor.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 2)
    }

    private func cosmeticsForLook(_ look: Look, limit: Int) -> [CosmeticItem] {
        let ids = Array(look.cosmeticIDs.prefix(limit))
        var result: [CosmeticItem] = []
        result.reserveCapacity(ids.count)

        for id in ids {
            if let item = catalogCosmetics.first(where: { $0.id == id }) {
                result.append(item)
            } else {
                result.append(
                    CosmeticItem(
                        id: id,
                        name: "",
                        category: .lipstick,
                        type: nil,
                        status: .inUse,
                        photoData: nil
                    )
                )
            }
        }
        return result
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Circle()
                .fill(AppColor.red)
                .frame(width: 22, height: 22)
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
        .buttonStyle(.plain)
        .padding(12)
    }

    private func dateTitle(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: date)
    }
}

private struct HeightMeasurer: View {
    let onChange: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: HeightKey.self, value: geo.size.height)
        }
        .onPreferenceChange(HeightKey.self) { h in
            onChange(h)
        }
    }
}

private struct HeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        result.reserveCapacity((count + size - 1) / size)
        var idx = 0
        while idx < count {
            let end = Swift.min(idx + size, count)
            result.append(Array(self[idx..<end]))
            idx = end
        }
        return result
    }
}

private struct OverlayMiniCosmeticCard: View {
    let item: CosmeticItem
    let onRemove: () -> Void

    private let size: CGFloat = 72
    private let corner: CGFloat = 14

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                ZStack {
                    RoundedRectangle(cornerRadius: corner, style: .continuous)
                        .fill(Color.white)

                    if let data = item.photoData, let ui = UIImage(data: data) {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFill()
                            .frame(width: size, height: size)
                            .clipped()
                    }
                }
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))

                Button(action: onRemove) {
                    Circle()
                        .fill(AppColor.red)
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                .buttonStyle(.plain)
                .offset(x: 6, y: -6)
            }

            Text(item.name)
                .font(AppFont.make(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .frame(width: size + 10)
        }
    }
}

private struct ContentHeightReader: View {
    let onChange: (CGFloat) -> Void

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(key: ContentHeightKey.self, value: geo.size.height)
        }
        .onPreferenceChange(ContentHeightKey.self) { h in
            onChange(h)
        }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NavigationStack {
        CalendarView()
            .environmentObject(BeautyStore())
    }
}

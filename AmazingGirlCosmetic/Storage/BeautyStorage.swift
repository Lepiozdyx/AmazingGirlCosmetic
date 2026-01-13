//
//  BeautyStore.swift
//  AmazingGirlCosmetic
//
//  Created by Алексей Авер on 17.12.2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class BeautyStore: ObservableObject {

    @Published private(set) var cosmetics: [CosmeticItem] = []
    @Published private(set) var looks: [Look] = []
    @Published private(set) var usage: [UsageEntry] = []

    private let storageKey = "amazing_girl_cosmetic_storage"

    private struct Storage: Codable {
        var cosmetics: [CosmeticItem]
        var looks: [Look]
        var usage: [UsageEntry]
    }

    init() {
        load()
    }

    // MARK: - Storage

    func save() {
        let storage = Storage(cosmetics: cosmetics, looks: looks, usage: usage)
        do {
            let data = try JSONEncoder().encode(storage)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ BeautyStore.save error:", error)
        }
    }

    func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            cosmetics = []
            looks = []
            usage = []
            return
        }

        do {
            let storage = try JSONDecoder().decode(Storage.self, from: data)
            cosmetics = storage.cosmetics
            looks = storage.looks
            usage = storage.usage
        } catch {
            print("❌ BeautyStore.load error:", error)
            cosmetics = []
            looks = []
            usage = []
        }
    }

    func resetAll() {
        cosmetics = []
        looks = []
        usage = []
        UserDefaults.standard.removeObject(forKey: storageKey)
    }

    // MARK: - DayKey

    func dayKey(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 1970
        let m = comps.month ?? 1
        let d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    // MARK: - Finders

    func cosmetic(by id: UUID) -> CosmeticItem? {
        cosmetics.first(where: { $0.id == id })
    }

    func look(by id: UUID) -> Look? {
        looks.first(where: { $0.id == id })
    }

    // MARK: - Cosmetics CRUD

    func addCosmetic(
        name: String,
        category: CosmeticCategory,
        type: CosmeticType?,
        status: CosmeticStatus,
        photoData: Data?
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = CosmeticItem(
            name: trimmed,
            category: category,
            type: type,
            status: status,
            photoData: photoData
        )

        cosmetics.insert(item, at: 0)
        save()
    }

    func updateCosmetic(_ item: CosmeticItem) {
        guard let idx = cosmetics.firstIndex(where: { $0.id == item.id }) else { return }

        let trimmed = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        cosmetics[idx] = CosmeticItem(
            id: item.id,
            name: trimmed,
            category: item.category,
            type: item.type,
            status: item.status,
            photoData: item.photoData
        )
        save()
    }

    func deleteCosmetic(id: UUID) {
        cosmetics.removeAll { $0.id == id }

        looks = looks.map { look in
            var l = look
            l.cosmeticIDs.removeAll { $0 == id }
            return l
        }

        for i in usage.indices {
            usage[i].cosmeticIDs.removeAll { $0 == id }
        }
        cleanupEmptyDays()

        save()
    }

    // MARK: - Looks CRUD

    func addLook(title: String, note: String?, cosmeticIDs: [UUID]) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let uniqueCosmetics = uniqueOrdered(cosmeticIDs)

        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = (trimmedNote?.isEmpty == true) ? nil : trimmedNote

        let look = Look(title: trimmedTitle, note: finalNote, cosmeticIDs: uniqueCosmetics)
        looks.insert(look, at: 0)
        save()
    }

    func updateLook(_ look: Look) {
        guard let idx = looks.firstIndex(where: { $0.id == look.id }) else { return }

        let trimmedTitle = look.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let trimmedNote = look.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalNote = (trimmedNote?.isEmpty == true) ? nil : trimmedNote

        let uniqueCosmetics = uniqueOrdered(look.cosmeticIDs)

        looks[idx] = Look(
            id: look.id,
            title: trimmedTitle,
            note: finalNote,
            cosmeticIDs: uniqueCosmetics
        )
        save()
    }

    func deleteLook(id: UUID) {
        looks.removeAll { $0.id == id }

        for i in usage.indices {
            usage[i].lookIDs.removeAll { $0 == id }
        }
        cleanupEmptyDays()

        save()
    }

    // MARK: - Usage (Day)

    func usageEntry(for dayKey: String) -> UsageEntry? {
        usage.first(where: { $0.dayKey == dayKey })
    }

    func usageEntry(for date: Date) -> UsageEntry? {
        usageEntry(for: dayKey(for: date))
    }

    private func ensureUsageIndex(for dayKey: String) -> Int {
        if let idx = usage.firstIndex(where: { $0.dayKey == dayKey }) {
            return idx
        }
        let new = UsageEntry(dayKey: dayKey, lookIDs: [], cosmeticIDs: [])
        usage.append(new)
        return usage.count - 1
    }

    func setUsageForDay(dayKey: String, lookIDs: [UUID], cosmeticIDs: [UUID]) {
        let idx = ensureUsageIndex(for: dayKey)

        usage[idx].lookIDs = uniqueOrdered(lookIDs)
        usage[idx].cosmeticIDs = uniqueOrdered(cosmeticIDs)

        if usage[idx].lookIDs.isEmpty && usage[idx].cosmeticIDs.isEmpty {
            usage.remove(at: idx)
        }

        save()
    }

    func clearDay(dayKey: String) {
        usage.removeAll { $0.dayKey == dayKey }
        save()
    }

    func addLookToDay(dayKey: String, lookID: UUID) {
        let idx = ensureUsageIndex(for: dayKey)
        if !usage[idx].lookIDs.contains(lookID) {
            usage[idx].lookIDs.append(lookID)
            save()
        }
    }

    func removeLookFromDay(dayKey: String, lookID: UUID) {
        guard let idx = usage.firstIndex(where: { $0.dayKey == dayKey }) else { return }
        usage[idx].lookIDs.removeAll { $0 == lookID }
        cleanupDayIfEmpty(index: idx)
        save()
    }

    func addCosmeticToDay(dayKey: String, cosmeticID: UUID) {
        let idx = ensureUsageIndex(for: dayKey)
        if !usage[idx].cosmeticIDs.contains(cosmeticID) {
            usage[idx].cosmeticIDs.append(cosmeticID)
            save()
        }
    }

    func removeCosmeticFromDay(dayKey: String, cosmeticID: UUID) {
        guard let idx = usage.firstIndex(where: { $0.dayKey == dayKey }) else { return }
        usage[idx].cosmeticIDs.removeAll { $0 == cosmeticID }
        cleanupDayIfEmpty(index: idx)
        save()
    }

    // MARK: - Compatibility (если где-то уже вызываешь productID)

    func addProductToDay(dayKey: String, productID: UUID) {
        addCosmeticToDay(dayKey: dayKey, cosmeticID: productID)
    }

    func removeProductFromDay(dayKey: String, productID: UUID) {
        removeCosmeticFromDay(dayKey: dayKey, cosmeticID: productID)
    }

    // MARK: - Checks for Calendar dots

    func hasLooks(on date: Date) -> Bool {
        let key = dayKey(for: date)
        return usageEntry(for: key)?.hasLooks ?? false
    }

    func hasCosmetics(on date: Date) -> Bool {
        let key = dayKey(for: date)
        return usageEntry(for: key)?.hasCosmetics ?? false
    }

    // MARK: - Filters

    func inUseCosmetics() -> [CosmeticItem] {
        cosmetics.filter { $0.status == .inUse }
    }

    // MARK: - Cleanup

    private func cleanupDayIfEmpty(index: Int) {
        guard usage.indices.contains(index) else { return }
        if usage[index].lookIDs.isEmpty && usage[index].cosmeticIDs.isEmpty {
            usage.remove(at: index)
        }
    }

    private func cleanupEmptyDays() {
        usage.removeAll { $0.lookIDs.isEmpty && $0.cosmeticIDs.isEmpty }
    }

    private func uniqueOrdered(_ ids: [UUID]) -> [UUID] {
        var seen: Set<UUID> = []
        var result: [UUID] = []
        result.reserveCapacity(ids.count)

        for id in ids {
            if seen.insert(id).inserted {
                result.append(id)
            }
        }
        return result
    }
}

// MARK: - Helpers used by UI

extension BeautyStore {

    func cosmeticsForLook(_ look: Look, limit: Int) -> [CosmeticItem] {
        let ids = Array(look.cosmeticIDs.prefix(limit))
        var result: [CosmeticItem] = []
        result.reserveCapacity(ids.count)

        for id in ids {
            if let item = cosmetics.first(where: { $0.id == id }) {
                result.append(item)
            }
        }
        return result
    }

    func hasLookUsage(on date: Date) -> Bool {
        let key = dayKey(for: date)
        return usage.contains { (entry: UsageEntry) in
            entry.dayKey == key && !entry.lookIDs.isEmpty
        }
    }

    func hasCosmeticsUsage(on date: Date) -> Bool {
        let key = dayKey(for: date)
        return usage.contains { (entry: UsageEntry) in
            entry.dayKey == key && !entry.cosmeticIDs.isEmpty
        }
    }

    var hasAnyUsageToday: Bool {
        let key = dayKey(for: Date())
        return usage.contains { (entry: UsageEntry) in
            entry.dayKey == key && (!entry.lookIDs.isEmpty || !entry.cosmeticIDs.isEmpty)
        }
    }

    func todaysLooks() -> [Look] {
        let key = dayKey(for: Date())

        let ids: [UUID] = usage
            .filter { (e: UsageEntry) in e.dayKey == key }
            .flatMap { (e: UsageEntry) in e.lookIDs }

        guard !ids.isEmpty else { return [] }
        return looks.filter { ids.contains($0.id) }
    }

    func todaysCosmetics() -> [CosmeticItem] {
        let key = dayKey(for: Date())

        let ids: [UUID] = usage
            .filter { (e: UsageEntry) in e.dayKey == key }
            .flatMap { (e: UsageEntry) in e.cosmeticIDs }

        guard !ids.isEmpty else { return [] }

        var result: [CosmeticItem] = []
        result.reserveCapacity(ids.count)

        for id in ids {
            if let item = cosmetics.first(where: { $0.id == id }) {
                result.append(item)
            }
        }
        return result
    }
}

extension BeautyStore {
    func looksForDay(_ date: Date) -> [Look] {
        let key = dayKey(for: date)
        let ids: [UUID] = usage
            .filter { $0.dayKey == key }
            .flatMap { $0.lookIDs }

        guard !ids.isEmpty else { return [] }
        return looks.filter { ids.contains($0.id) }
    }

    func cosmeticsForDay(_ date: Date) -> [CosmeticItem] {
        let key = dayKey(for: date)
        let ids: [UUID] = usage
            .filter { $0.dayKey == key }
            .flatMap { $0.cosmeticIDs }

        guard !ids.isEmpty else { return [] }

        var result: [CosmeticItem] = []
        result.reserveCapacity(ids.count)

        for id in ids {
            if let item = cosmetics.first(where: { $0.id == id }) {
                result.append(item)
            }
        }
        return result
    }
}

extension BeautyStore {
    func usageInRange(startDate: Date, endDate: Date) -> [UsageEntry] {
        let cal = Calendar.current
        let start = cal.startOfDay(for: startDate)
        let end = cal.startOfDay(for: endDate)

        return usage.filter { entry in
            guard let d = parseDayKey(entry.dayKey) else { return false }
            let day = cal.startOfDay(for: d)
            return day >= start && day <= end
        }
    }

    func lastUsageDate(for category: CosmeticCategory) -> Date? {
        let cal = Calendar.current
        var last: Date? = nil

        for entry in usage {
            guard let d = parseDayKey(entry.dayKey) else { continue }
            let day = cal.startOfDay(for: d)

            var used = false
            for id in entry.cosmeticIDs {
                if let item = cosmetic(by: id), item.category == category {
                    used = true
                    break
                }
            }

            if used {
                if let prev = last {
                    if day > prev { last = day }
                } else {
                    last = day
                }
            }
        }

        return last
    }

    func suggestedLookTitle(forMissingCategory category: CosmeticCategory) -> String? {
        let lower = category.rawValue.lowercased()

        if let match = looks.first(where: { $0.title.lowercased().contains("party") }) {
            return match.title
        }

        if lower.contains("eyeshadow"),
           let match = looks.first(where: { $0.title.lowercased().contains("party") }) {
            return match.title
        }

        return looks.first?.title
    }

    func parseDayKey(_ key: String) -> Date? {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df.date(from: key)
    }
}

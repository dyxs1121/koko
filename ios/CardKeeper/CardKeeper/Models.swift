import Foundation

// MARK: - 账单流水

struct Transaction: Identifiable, Codable, Hashable {
    var id = UUID()
    var merchant: String
    var category: String
    var amount: Double
    var date: Date
}

// MARK: - 活动

enum ActivityKind: String, Codable, CaseIterable, Identifiable {
    case count
    case amount
    case once

    var id: String { rawValue }

    var label: String {
        switch self {
        case .count: return "按次数"
        case .amount: return "按金额"
        case .once: return "单次完成"
        }
    }

    var shortLabel: String {
        switch self {
        case .count: return "次数"
        case .amount: return "金额"
        case .once: return "单次"
        }
    }
}

enum RemindRule: String, Codable, CaseIterable, Identifiable {
    case weeklySunday = "每周日 20:00"
    case weeklyFriday = "每周五 08:00"
    case monthlyFirst = "每月 1 日 09:00"
    case daily = "每天 09:00"
    case dayBefore = "截止前 1 天 09:00"
    case none = "不提醒"

    var id: String { rawValue }
}

struct ActivityStep: Identifiable, Codable, Hashable {
    var id = UUID()
    var label: String
    var done: Bool
}

struct Activity: Identifiable, Codable, Hashable {
    var id = UUID()
    var cardID: UUID
    var title: String
    var detail: String
    var kind: ActivityKind
    var target: Double
    var current: Double = 0
    var deadline: Date
    var remind: RemindRule = .weeklySunday
    var steps: [ActivityStep] = []

    var doneCount: Int { steps.filter { $0.done }.count }

    /// 进度值：金额型用累加金额，其余用已打卡次数
    var value: Double {
        kind == .amount ? current : Double(doneCount)
    }

    var isDone: Bool { value >= target - 0.0001 }

    var ratio: Double {
        guard target > 0 else { return 0 }
        return min(1, max(0, value / target))
    }

    var percentText: String { "\(Int((ratio * 100).rounded()))%" }

    var remainText: String {
        if kind == .amount {
            return "还差 " + Fmt.yuan(max(0, target - value))
        }
        return "\(Int(value)) / \(Int(target)) 次"
    }
}

// MARK: - 信用卡

struct CreditCard: Identifiable, Codable, Hashable {
    var id = UUID()
    var bank: String
    var name: String
    var org: String
    var last4: String
    var limit: Double
    var used: Double
    var billDay: Int
    var dueDay: Int
    var paid: Double
    var colorA: String
    var colorB: String
    var remind: Bool
    var remindDays: Int
    var items: [Transaction]

    var short: String {
        let s = bank.replacingOccurrences(of: "银行", with: "")
        return s.isEmpty ? bank : s
    }

    var billTotal: Double { items.reduce(0) { $0 + $1.amount } }

    var outstanding: Double { max(0, billTotal - paid) }

    var isCleared: Bool { outstanding < 0.005 }

    var usedRatio: Double { limit > 0 ? min(1, used / limit) : 0 }

    var dueLabel: String {
        if isCleared { return "本期已结清" }
        let d = DateHelp.daysToDue(dueDay)
        if d <= 0 { return "今天还款" }
        if d == 1 { return "明天还款" }
        return "\(d) 天后还款"
    }

    static var empty: CreditCard {
        CreditCard(bank: "", name: "", org: "银联", last4: "", limit: 30000, used: 0,
                   billDay: 10, dueDay: 28, paid: 0, colorA: "1B1D2B", colorB: "3B4067",
                   remind: true, remindDays: 3, items: [])
    }
}

// MARK: - 设置

struct AppSettings: Codable {
    var billPush: Bool = true
    var actPush: Bool = true
    var quietHours: Bool = true
}

// MARK: - 数据仓库

final class Store: ObservableObject {

    @Published var cards: [CreditCard] = []
    @Published var activities: [Activity] = []
    @Published var settings = AppSettings()

    private let storageKey = "cardkeeper.state.v1"

    struct Snapshot: Codable {
        var cards: [CreditCard]
        var activities: [Activity]
        var settings: AppSettings
    }

    init() {
        let loaded = load()
        if !loaded { seed() }
    }

    // MARK: 读写

    @discardableResult
    func load() -> Bool {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let snap = try? JSONDecoder().decode(Snapshot.self, from: data) else {
            return false
        }
        cards = snap.cards
        activities = snap.activities
        settings = snap.settings
        return true
    }

    func save() {
        let snap = Snapshot(cards: cards, activities: activities, settings: settings)
        guard let data = try? JSONEncoder().encode(snap) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    // MARK: 派生

    var totalOutstanding: Double { cards.reduce(0) { $0 + $1.outstanding } }
    var totalBill: Double { cards.reduce(0) { $0 + $1.billTotal } }
    var totalPaid: Double { cards.reduce(0) { $0 + $1.paid } }
    var totalLimit: Double { cards.reduce(0) { $0 + $1.limit } }
    var totalUsed: Double { cards.reduce(0) { $0 + $1.used } }

    var paidRatio: Double {
        totalBill > 0 ? min(1, totalPaid / totalBill) : 0
    }

    var nearestCard: CreditCard? {
        cards.filter { !$0.isCleared }
            .sorted { DateHelp.daysToDue($0.dueDay) < DateHelp.daysToDue($1.dueDay) }
            .first
    }

    func card(_ id: UUID) -> CreditCard? {
        cards.first { $0.id == id }
    }

    func cardName(_ id: UUID) -> String {
        guard let c = card(id) else { return "未知卡片" }
        return c.short + " ••" + c.last4
    }

    func categoryTotals() -> [(name: String, value: Double, color: String)] {
        var map: [String: Double] = [:]
        for c in cards {
            for t in c.items {
                map[t.category, default: 0] += t.amount
            }
        }
        let list = map.map { (name: $0.key, value: $0.value, color: $0.key) }
        return list.sorted { $0.value > $1.value }
    }

    // MARK: 活动操作

    func toggleStep(activityID: UUID, index: Int) {
        guard let i = activities.firstIndex(where: { $0.id == activityID }),
              activities[i].steps.indices.contains(index) else { return }
        activities[i].steps[index].done.toggle()
        save()
    }

    func checkNextStep(activityID: UUID) {
        guard let i = activities.firstIndex(where: { $0.id == activityID }) else { return }
        guard let j = activities[i].steps.firstIndex(where: { !$0.done }) else { return }
        activities[i].steps[j].done = true
        save()
    }

    func undoLastStep(activityID: UUID) {
        guard let i = activities.firstIndex(where: { $0.id == activityID }) else { return }
        for j in stride(from: activities[i].steps.count - 1, through: 0, by: -1) {
            if activities[i].steps[j].done {
                activities[i].steps[j].done = false
                save()
                return
            }
        }
    }

    func addAmount(activityID: UUID, amount: Double) {
        guard let i = activities.firstIndex(where: { $0.id == activityID }) else { return }
        activities[i].current += amount
        save()
    }

    func setDone(activityID: UUID, done: Bool) {
        guard let i = activities.firstIndex(where: { $0.id == activityID }) else { return }
        if done {
            if activities[i].kind == .amount {
                activities[i].current = activities[i].target
            } else {
                for j in activities[i].steps.indices {
                    activities[i].steps[j].done = true
                }
            }
        } else {
            activities[i].current = 0
            for j in activities[i].steps.indices {
                activities[i].steps[j].done = false
            }
        }
        save()
    }

    func deleteActivity(_ id: UUID) {
        activities.removeAll { $0.id == id }
        save()
    }

    func deleteCard(_ id: UUID) {
        cards.removeAll { $0.id == id }
        activities.removeAll { $0.cardID == id }
        save()
    }

    // MARK: 演示数据

    private func seed() {
        let c1 = CreditCard(
            bank: "招商银行", name: "经典白金卡", org: "VISA", last4: "4832",
            limit: 80000, used: 32800, billDay: 5, dueDay: 23, paid: 1000,
            colorA: "1B1D2B", colorB: "3B4067", remind: true, remindDays: 3,
            items: [
                Transaction(merchant: "京东商城", category: "购物", amount: 899.00, date: DateHelp.thisMonth(day: 16)),
                Transaction(merchant: "中石化 · 建国路站", category: "加油", amount: 400.00, date: DateHelp.thisMonth(day: 14)),
                Transaction(merchant: "盒马鲜生 朝阳店", category: "超市", amount: 268.50, date: DateHelp.thisMonth(day: 12)),
                Transaction(merchant: "星巴克 国贸店", category: "餐饮", amount: 38.00, date: DateHelp.thisMonth(day: 11)),
                Transaction(merchant: "美团外卖", category: "餐饮", amount: 145.60, date: DateHelp.thisMonth(day: 9)),
                Transaction(merchant: "Apple Music", category: "订阅", amount: 68.00, date: DateHelp.thisMonth(day: 8)),
                Transaction(merchant: "地铁出行", category: "交通", amount: 24.00, date: DateHelp.thisMonth(day: 7)),
                Transaction(merchant: "优衣库 三里屯", category: "购物", amount: 329.90, date: DateHelp.thisMonth(day: 5))
            ])

        let c2 = CreditCard(
            bank: "交通银行", name: "太平洋信用卡", org: "Mastercard", last4: "7719",
            limit: 50000, used: 11200, billDay: 8, dueDay: 27, paid: 0,
            colorA: "15303C", colorB: "1F5E70", remind: true, remindDays: 3,
            items: [
                Transaction(merchant: "小米之家", category: "购物", amount: 599.00, date: DateHelp.thisMonth(day: 15)),
                Transaction(merchant: "瑞幸咖啡", category: "餐饮", amount: 32.00, date: DateHelp.thisMonth(day: 13)),
                Transaction(merchant: "滴滴出行", category: "交通", amount: 28.50, date: DateHelp.thisMonth(day: 10)),
                Transaction(merchant: "中石化 · 望京站", category: "加油", amount: 300.00, date: DateHelp.thisMonth(day: 6))
            ])

        let c3 = CreditCard(
            bank: "中信银行", name: "魔力白金卡", org: "银联", last4: "2065",
            limit: 30000, used: 6800, billDay: 12, dueDay: 28, paid: 0,
            colorA: "3A1F2E", colorB: "6B2E44", remind: true, remindDays: 5,
            items: [
                Transaction(merchant: "美团买菜", category: "超市", amount: 156.80, date: DateHelp.thisMonth(day: 16)),
                Transaction(merchant: "中石油 · 亦庄站", category: "加油", amount: 300.00, date: DateHelp.thisMonth(day: 12)),
                Transaction(merchant: "万达影城", category: "娱乐", amount: 88.00, date: DateHelp.thisMonth(day: 8))
            ])

        let c4 = CreditCard(
            bank: "浦发银行", name: "AE 白金卡", org: "AE", last4: "9014",
            limit: 100000, used: 9000, billDay: 18, dueDay: 6, paid: 682,
            colorA: "20242B", colorB: "3F4650", remind: false, remindDays: 7,
            items: [
                Transaction(merchant: "日上免税行", category: "购物", amount: 682.00, date: DateHelp.thisMonth(day: 4))
            ])

        cards = [c1, c2, c3, c4]

        activities = [
            Activity(cardID: c1.id, title: "月月刷 · 满 3000 返 100",
                     detail: "当月累计消费满 3,000 元，次月返 100 元刷卡金",
                     kind: .amount, target: 3000, current: 2173,
                     deadline: DateHelp.thisMonth(day: 30), remind: .weeklySunday),

            Activity(cardID: c2.id, title: "最红星期五 · 5 折",
                     detail: "每周五单笔满 100 元享 5 折，每月最多 4 次",
                     kind: .count, target: 4, deadline: DateHelp.thisMonth(day: 30), remind: .weeklyFriday,
                     steps: [
                        ActivityStep(label: "第 1 周 · 已完成", done: true),
                        ActivityStep(label: "第 2 周 · 已完成", done: true),
                        ActivityStep(label: "第 3 周", done: false),
                        ActivityStep(label: "第 4 周", done: false)
                     ]),

            Activity(cardID: c3.id, title: "加油返现 8%",
                     detail: "每月在中石油 / 中石化消费 2 笔，返现 8%",
                     kind: .count, target: 2, deadline: DateHelp.thisMonth(day: 30), remind: .monthlyFirst,
                     steps: [
                        ActivityStep(label: "第 1 笔加油", done: true),
                        ActivityStep(label: "第 2 笔加油", done: true)
                     ]),

            Activity(cardID: c4.id, title: "超市满 200 减 30",
                     detail: "指定超市单笔满 200 元立减 30 元，每月 1 次",
                     kind: .once, target: 1, deadline: DateHelp.thisMonth(day: 25), remind: .dayBefore,
                     steps: [ActivityStep(label: "完成一笔满 200 元消费", done: false)])
        ]

        save()
    }

    func reset() {
        cards = []
        activities = []
        settings = AppSettings()
        seed()
    }
}

// MARK: - 日期工具

enum DateHelp {
    static let cal = Calendar.current

    static func thisMonth(day: Int, hour: Int = 12) -> Date {
        var c = cal.dateComponents([.year, .month], from: Date())
        c.day = min(max(day, 1), 28)
        c.hour = hour
        return cal.date(from: c) ?? Date()
    }

    static func nextOccurrence(day: Int) -> Date {
        let today = cal.startOfDay(for: Date())
        var c = cal.dateComponents([.year, .month], from: today)
        c.day = min(max(day, 1), 28)
        var d = cal.date(from: c) ?? today
        if d < today {
            d = cal.date(byAdding: .month, value: 1, to: d) ?? d
        }
        return d
    }

    static func daysUntil(_ date: Date) -> Int {
        let a = cal.startOfDay(for: Date())
        let b = cal.startOfDay(for: date)
        return cal.dateComponents([.day], from: a, to: b).day ?? 0
    }

    static func daysToDue(_ day: Int) -> Int {
        daysUntil(nextOccurrence(day: day))
    }

    static func daysToDeadline(_ date: Date) -> Int {
        daysUntil(date)
    }
}

import SwiftUI

struct BillsView: View {
    @EnvironmentObject var store: Store
    @State private var filter: UUID? = nil

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    chips
                        .padding(.top, 14)

                    summary
                        .padding(.horizontal, 20)
                        .padding(.top, 14)

                    SectionHeader(title: "消费明细", trailing: "\(rows.count) 笔")
                        .padding(.horizontal, 20)

                    detailList
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
            }
        }
    }

    // MARK: 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Fmt.todayLine())
                .font(.system(size: 12.5))
                .foregroundColor(Palette.sub)
            Text("账单")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(Palette.text)
        }
    }

    // MARK: 卡片筛选

    private var chips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipButton(title: "全部", active: filter == nil) {
                    filter = nil
                }

                ForEach(store.cards) { card in
                    chipButton(title: card.short + " ••" + card.last4, active: filter == card.id) {
                        filter = card.id
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 2)
        }
    }

    private func chipButton(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(active ? .white : Color(hex: "48484A"))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(active ? Color(hex: "161821") : Color.white)
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(active ? 0.20 : 0.05), radius: active ? 8 : 1.5, x: 0, y: active ? 4 : 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: 汇总

    private var scopedCards: [CreditCard] {
        if let id = filter { return store.cards.filter { $0.id == id } }
        return store.cards
    }

    private var summary: some View {
        let total = scopedCards.reduce(0) { $0 + $1.billTotal }
        let paid = scopedCards.reduce(0) { $0 + $1.paid }
        let due = max(0, total - paid)

        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("本期账单 · 账单日 " + billDayText)
                        .font(.system(size: 12.5))
                        .foregroundColor(Palette.sub)
                    Text(Fmt.money(due))
                        .font(.system(size: 31, weight: .bold))
                        .foregroundColor(Palette.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.top, 2)
                    Text("待还金额 · 账单合计 " + Fmt.money(total))
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.sub)
                        .padding(.top, 2)
                }

                Spacer(minLength: 8)

                PillView(text: periodText,
                         fg: Palette.blue,
                         bg: Palette.blue.opacity(0.10))
            }

            Rectangle()
                .fill(Palette.line)
                .frame(height: 0.5)
                .padding(.top, 14)

            HStack(spacing: 0) {
                splitCell("已还", Fmt.money(paid), Palette.green)
                splitCell("最低还款", Fmt.money(due * 0.1), Palette.text)
                splitCell("还款日", dueDayText, Palette.text)
            }
            .padding(.top, 13)
        }
        .padding(18)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 1.5, x: 0, y: 1)
    }

    private var billDayText: String {
        if let id = filter, let c = store.card(id) { return "每月 \(c.billDay) 日" }
        return "各卡"
    }

    private var dueDayText: String {
        if let id = filter, let c = store.card(id) { return "每月 \(c.dueDay) 日" }
        return "各卡不同"
    }

    private var periodText: String {
        let start = DateHelp.thisMonth(day: 5)
        let end = DateHelp.thisMonth(day: 4)
        return Fmt.monthDay(start) + " – " + Fmt.monthDay(end)
    }

    private func splitCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10.5))
                .foregroundColor(Palette.sub)
            Text(value)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 明细

    private var rows: [BillRow] {
        var out: [BillRow] = []
        for c in scopedCards {
            for t in c.items {
                out.append(BillRow(id: t.id, tx: t, card: c))
            }
        }
        return out
    }

    private var groups: [DayGroup] {
        let dict = Dictionary(grouping: rows) { Fmt.dayLabel($0.tx.date) }
        return dict
            .map { DayGroup(key: $0.key, items: $0.value.sorted { $0.tx.amount > $1.tx.amount }) }
            .sorted { $0.key > $1.key }
    }

    private var detailList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(groups) { group in
                Text(dayTitle(group.key))
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(Palette.sub)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    .padding(.leading, 4)

                CardShell {
                    VStack(spacing: 0) {
                        ForEach(Array(group.items.enumerated()), id: \.offset) { index, row in
                            txRow(row)
                            if index < group.items.count - 1 {
                                RowDivider()
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayTitle(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2 else { return key }
        return "\(Int(parts[0]) ?? 0) 月 \(Int(parts[1]) ?? 0) 日"
    }

    private func txRow(_ row: BillRow) -> some View {
        HStack(spacing: 12) {
            IconBadge(text: String(row.tx.category.prefix(1)),
                      color: Palette.category(row.tx.category))

            VStack(alignment: .leading, spacing: 2) {
                Text(row.tx.merchant)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Palette.text)
                    .lineLimit(1)
                Text(row.tx.category + " · " + row.card.short + " ••" + row.card.last4)
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.sub)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text(Fmt.money(row.tx.amount))
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Palette.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }
}

struct BillRow: Identifiable {
    let id: UUID
    var tx: Transaction
    var card: CreditCard
}

struct DayGroup: Identifiable {
    var id: String { key }
    var key: String
    var items: [BillRow]
}

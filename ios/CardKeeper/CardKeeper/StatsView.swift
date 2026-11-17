import SwiftUI

struct StatsView: View {
    @EnvironmentObject var store: Store

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    topStats
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    donutPanel
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    trendPanel
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    limitPanel
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    rankPanel
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
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
            Text("消费统计")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(Palette.text)
        }
    }

    // MARK: 概览

    private var avgTicket: Double {
        let count = store.cards.reduce(0) { $0 + $1.items.count }
        guard count > 0 else { return 0 }
        return store.totalBill / Double(count)
    }

    private var itemCount: Int {
        store.cards.reduce(0) { $0 + $1.items.count }
    }

    private var deltaVsLastMonth: Double {
        let last = 4980.0
        guard last > 0 else { return 0 }
        return (store.totalBill - last) / last * 100
    }

    private var topStats: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 5) {
                Text("本月消费")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
                Text(Fmt.yuan(store.totalBill))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 3) {
                    Image(systemName: deltaVsLastMonth >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 9, weight: .bold))
                    Text(String(format: "%.1f%%", abs(deltaVsLastMonth)) + " 较上月")
                        .font(.system(size: 10.5))
                }
                .foregroundColor(deltaVsLastMonth >= 0 ? Palette.red : Palette.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
                Text("笔均消费")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
                Text(Fmt.yuan(avgTicket))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Palette.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("共 \(itemCount) 笔")
                    .font(.system(size: 10.5))
                    .foregroundColor(Palette.sub)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    // MARK: 支出构成

    private var categories: [(name: String, value: Double, color: String)] {
        store.categoryTotals()
    }

    private var donutPanel: some View {
        let total = categories.reduce(0) { $0 + $1.value }

        return CardShell {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("支出构成")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Palette.text)
                    Spacer()
                    Text("本月")
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.sub)
                }

                HStack(spacing: 10) {
                    DonutChart(segments: categories.map { (value: $0.value, color: Palette.category($0.name)) },
                               total: total)

                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(Array(categories.prefix(5).enumerated()), id: \.offset) { _, item in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(Palette.category(item.name))
                                    .frame(width: 8, height: 8)
                                Text(item.name)
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "3A3A3C"))
                                Spacer()
                                Text("\(total > 0 ? Int((item.value / total * 100).rounded()) : 0)%")
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Palette.sub)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.top, 14)
            }
            .padding(16)
        }
    }

    // MARK: 月度趋势

    private var history: [MonthBar] {
        let base: [Double] = [3860, 4120, 5280, 3140, 4980]
        let month = Calendar.current.component(.month, from: Date())
        var out: [MonthBar] = []
        for i in 0..<5 {
            var m = month - 5 + i
            while m <= 0 { m += 12 }
            out.append(MonthBar(label: "\(m)月", value: base[i], current: false))
        }
        out.append(MonthBar(label: "\(month)月", value: store.totalBill, current: true))
        return out
    }

    private var trendPanel: some View {
        let bars = history
        let maxValue = max(bars.map { $0.value }.max() ?? 1, 1)
        let avg = bars.reduce(0) { $0 + $1.value } / Double(max(bars.count, 1))

        return CardShell {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("近 6 个月趋势")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Palette.text)
                    Spacer()
                    Text("月均 " + Fmt.yuan(avg))
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.sub)
                }

                HStack(alignment: .bottom, spacing: 9) {
                    ForEach(bars) { bar in
                        VStack(spacing: 7) {
                            Spacer(minLength: 0)
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(bar.current
                                      ? AnyShapeStyle(LinearGradient(colors: [Color(hex: "2B2E3D"), Color(hex: "14161F")], startPoint: .top, endPoint: .bottom))
                                      : AnyShapeStyle(LinearGradient(colors: [Color(hex: "8FA9FF"), Color(hex: "6C7DFF")], startPoint: .top, endPoint: .bottom)))
                                .frame(height: max(8, CGFloat(bar.value / maxValue) * 96))
                            Text(bar.label)
                                .font(.system(size: 10, weight: bar.current ? .semibold : .regular))
                                .foregroundColor(bar.current ? Palette.text : Palette.sub)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 130)
                .padding(.top, 14)
            }
            .padding(16)
        }
    }

    // MARK: 额度

    private var limitPanel: some View {
        CardShell {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline) {
                    Text("额度使用")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Palette.text)
                    Spacer()
                    Text("总授信 " + Fmt.yuan(store.totalLimit))
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.sub)
                }

                ForEach(Array(store.cards.enumerated()), id: \.offset) { index, card in
                    HStack(spacing: 10) {
                        Text(card.short)
                            .font(.system(size: 12.5, weight: .medium))
                            .foregroundColor(Palette.text)
                            .frame(width: 44, alignment: .leading)

                        BarView(value: card.usedRatio, height: 7,
                                tint: card.usedRatio > 0.7
                                ? LinearGradient(colors: [Color(hex: "FF6B4A"), Palette.red], startPoint: .leading, endPoint: .trailing)
                                : Palette.accentGradient)

                        Text("\(Int(card.usedRatio * 100))% · " + Fmt.yuan(card.used))
                            .font(.system(size: 11))
                            .foregroundColor(Palette.sub)
                            .frame(width: 82, alignment: .trailing)
                            .lineLimit(1)
                    }
                    .padding(.top, index == 0 ? 14 : 11)
                }
            }
            .padding(16)
        }
    }

    // MARK: 排行

    private var topMerchants: [(name: String, value: Double)] {
        var map: [String: Double] = [:]
        for c in store.cards {
            for t in c.items {
                map[t.merchant, default: 0] += t.amount
            }
        }
        let sorted = map.map { (name: $0.key, value: $0.value) }.sorted { $0.value > $1.value }
        return Array(sorted.prefix(4))
    }

    private var rankPanel: some View {
        CardShell {
            VStack(alignment: .leading, spacing: 0) {
                Text("消费排行")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Palette.text)
                    .padding(.bottom, 4)

                ForEach(Array(topMerchants.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(index == 0 ? Palette.orange : Color(hex: "C7C7CC"))
                            .frame(width: 18, alignment: .leading)
                        Text(item.name)
                            .font(.system(size: 13))
                            .foregroundColor(Palette.text)
                            .lineLimit(1)
                        Spacer()
                        Text(Fmt.money(item.value))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Palette.text)
                    }
                    .padding(.top, 11)
                }
            }
            .padding(16)
        }
    }
}

// MARK: - 环形图

struct DonutChart: View {
    var segments: [(value: Double, color: Color)]
    var total: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "787880").opacity(0.08), lineWidth: 16)

            ForEach(Array(arcs.indices), id: \.self) { index in
                Circle()
                    .trim(from: arcs[index].start, to: arcs[index].end)
                    .stroke(arcs[index].color,
                            style: StrokeStyle(lineWidth: 16, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }

            VStack(spacing: 1) {
                Text("合计")
                    .font(.system(size: 10))
                    .foregroundColor(Palette.sub)
                Text(Fmt.yuan(total))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Palette.text)
            }
        }
        .frame(width: 142, height: 142)
    }

    private var arcs: [(start: CGFloat, end: CGFloat, color: Color)] {
        guard total > 0 else { return [] }
        var acc: Double = 0
        var out: [(start: CGFloat, end: CGFloat, color: Color)] = []
        for seg in segments {
            let fraction = seg.value / total
            if fraction <= 0 { continue }
            out.append((start: CGFloat(acc), end: CGFloat(acc + fraction), color: seg.color))
            acc += fraction
        }
        return out
    }
}

struct MonthBar: Identifiable {
    var id: String { label }
    var label: String
    var value: Double
    var current: Bool
}

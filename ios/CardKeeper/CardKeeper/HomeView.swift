import SwiftUI

struct HomeView: View {
    @EnvironmentObject var store: Store

    @State private var editingCard: CreditCard?
    @State private var addingCard = false

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    overview
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    SectionHeader(title: "我的卡片", trailing: "\(store.cards.count) 张 · 左右滑动")
                        .padding(.horizontal, 20)

                    cardStrip

                    SectionHeader(title: "近期提醒", trailing: "\(alerts.count) 条待处理")
                        .padding(.horizontal, 20)

                    alertsCard
                        .padding(.horizontal, 20)

                    SectionHeader(title: "在用权益", trailing: "本月")
                        .padding(.horizontal, 20)

                    rightsCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
            }
        }
        .sheet(item: $editingCard) { card in
            CardEditorView(card: card).environmentObject(store)
        }
        .sheet(isPresented: $addingCard) {
            CardEditorView(card: CreditCard.empty, isNew: true).environmentObject(store)
        }
    }

    // MARK: 顶部

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Fmt.todayLine())
                    .font(.system(size: 12.5))
                    .foregroundColor(Palette.sub)
                Text("我的卡片")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(Palette.text)
            }

            Spacer()

            Button {
                addingCard = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Palette.text)
                    .frame(width: 38, height: 38)
                    .background(Color(hex: "767680").opacity(0.12))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: 总览

    private var overview: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("本月应还合计")
                .font(.system(size: 12.5))
                .foregroundColor(.white.opacity(0.58))

            Text(Fmt.money(store.totalOutstanding))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .padding(.top, 4)

            HStack(spacing: 8) {
                Text("\(store.cards.count) 张卡 · 已还 " + Fmt.money(store.totalPaid))
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.62))
                    .lineLimit(1)

                Spacer(minLength: 4)

                if let nearest = store.nearestCard {
                    PillView(text: nearest.short + " " + nearest.dueLabel,
                             fg: Color(hex: "FFCF8A"),
                             bg: Color(hex: "FF9F0A").opacity(0.16))
                } else {
                    PillView(text: "全部已还清",
                             fg: Color(hex: "9BE8B4"),
                             bg: Color(hex: "2CC15D").opacity(0.16))
                }
            }
            .padding(.top, 9)

            BarView(value: store.paidRatio, height: 5)
                .padding(.top, 14)

            HStack(spacing: 14) {
                legendDot(Color(hex: "6E8BFF"), "已还 \(Int(store.paidRatio * 100))%")
                legendDot(Color.white.opacity(0.25), "账单合计 " + Fmt.money(store.totalBill))
                Spacer()
            }
            .padding(.top, 11)
        }
        .padding(20)
        .background(Palette.darkGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "121628").opacity(0.35), radius: 18, x: 0, y: 12)
    }

    private func legendDot(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 6, height: 6)
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: 卡片横滑

    private var cardStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.cards) { card in
                    CardFace(card: card)
                        .frame(width: 296)
                        .onTapGesture {
                            editingCard = card
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 3)
        }
    }

    // MARK: 提醒

    private var alerts: [AlertItem] {
        var list: [AlertItem] = []

        let owing = store.cards
            .filter { !$0.isCleared }
            .sorted { DateHelp.daysToDue($0.dueDay) < DateHelp.daysToDue($1.dueDay) }

        for c in owing.prefix(2) {
            list.append(AlertItem(
                icon: "还",
                color: Palette.red,
                title: c.bank + " 还款提醒",
                subtitle: "每月 \(c.dueDay) 日 · " + c.dueLabel,
                trailing: Fmt.money(c.outstanding),
                warning: true))
        }

        for a in store.activities.filter({ !$0.isDone }).prefix(2) {
            let left = max(0, DateHelp.daysToDeadline(a.deadline))
            list.append(AlertItem(
                icon: "活",
                color: Palette.purple,
                title: a.title,
                subtitle: store.cardName(a.cardID) + " · " + Fmt.monthDay(a.deadline) + " 截止 · 剩 \(left) 天",
                trailing: a.remainText,
                warning: false))
        }

        return list
    }

    private var alertsCard: some View {
        CardShell {
            VStack(spacing: 0) {
                ForEach(Array(alerts.enumerated()), id: \.offset) { index, item in
                    alertRow(item)
                    if index < alerts.count - 1 {
                        RowDivider()
                    }
                }
            }
        }
    }

    private func alertRow(_ item: AlertItem) -> some View {
        HStack(spacing: 12) {
            IconBadge(text: item.icon, color: item.color)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Palette.text)
                    .lineLimit(1)
                Text(item.subtitle)
                    .font(.system(size: 11.5))
                    .foregroundColor(Palette.sub)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            Text(item.trailing)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(item.warning ? Palette.red : Palette.text)
                .lineLimit(1)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
    }

    // MARK: 权益

    private var rightsCard: some View {
        CardShell {
            HStack(spacing: 12) {
                IconBadge(text: "卡", color: Palette.green)

                VStack(alignment: .leading, spacing: 2) {
                    Text("可参与活动 \(store.activities.filter { !$0.isDone }.count) 个")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Palette.text)
                    Text("已完成 \(store.activities.filter { $0.isDone }.count) 个 · 全部清晰可见")
                        .font(.system(size: 11.5))
                        .foregroundColor(Palette.sub)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "C7C7CC"))
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 14)
        }
    }
}

struct AlertItem: Identifiable {
    let id = UUID()
    var icon: String
    var color: Color
    var title: String
    var subtitle: String
    var trailing: String
    var warning: Bool
}

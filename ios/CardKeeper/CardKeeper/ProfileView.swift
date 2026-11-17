import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var store: Store

    @State private var editing: CreditCard?
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    profileCard
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    SectionHeader(title: "提醒设置", trailing: "到点自动通知")
                        .padding(.horizontal, 20)

                    remindCard
                        .padding(.horizontal, 20)

                    SectionHeader(title: "卡片管理", trailing: "\(store.cards.count) 张")
                        .padding(.horizontal, 20)

                    cardManageList
                        .padding(.horizontal, 20)

                    SectionHeader(title: "其他", trailing: "")
                        .padding(.horizontal, 20)

                    otherCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 18)
                }
            }
        }
        .sheet(item: $editing) { card in
            CardEditorView(card: card).environmentObject(store)
        }
        .alert("恢复初始演示数据？", isPresented: $confirmReset) {
            Button("重置", role: .destructive) {
                store.reset()
                Notifier.shared.refresh(store: store)
            }
            Button("取消", role: .cancel) { }
        }
    }

    // MARK: 头部

    private var header: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(Fmt.todayLine())
                .font(.system(size: 12.5))
                .foregroundColor(Palette.sub)
            Text("我的")
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(Palette.text)
        }
    }

    // MARK: 个人卡片

    private var profileCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 13) {
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: "8FA9FF"), Color(hex: "6C5BFF")],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Text("卡")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("我的卡包")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(store.cards.count) 张卡 · 总授信 " + Fmt.yuan(store.totalLimit))
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()
            }

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 0.5)
                .padding(.top, 14)

            HStack(spacing: 0) {
                profileCell("已用额度", Fmt.yuan(store.totalUsed), .white)
                profileCell("可用额度", Fmt.yuan(store.totalLimit - store.totalUsed), .white)
                profileCell("待还", Fmt.yuan(store.totalOutstanding), Color(hex: "FFCF8A"))
            }
            .padding(.top, 13)
        }
        .padding(19)
        .background(LinearGradient(colors: [Color(hex: "242A3F"), Color(hex: "3A4260"), Color(hex: "4A4570")],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color(hex: "1B2038").opacity(0.3), radius: 16, x: 0, y: 10)
    }

    private func profileCell(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: 提醒设置

    private var remindCard: some View {
        CardShell {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    IconBadge(text: "账", color: Palette.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("出账提醒")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.text)
                        Text("账单日当天 09:00 推送本期账单")
                            .font(.system(size: 11.5))
                            .foregroundColor(Palette.sub)
                    }
                    Spacer()
                    Toggle("", isOn: $store.settings.billPush)
                        .labelsHidden()
                        .tint(Palette.green)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)

                RowDivider(inset: 48)

                HStack(spacing: 12) {
                    IconBadge(text: "活", color: Palette.purple)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("活动提醒")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.text)
                        Text("按活动设置的周期提前提醒")
                            .font(.system(size: 11.5))
                            .foregroundColor(Palette.sub)
                    }
                    Spacer()
                    Toggle("", isOn: $store.settings.actPush)
                        .labelsHidden()
                        .tint(Palette.green)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)

                RowDivider(inset: 48)

                HStack(spacing: 12) {
                    IconBadge(text: "静", color: Palette.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("免打扰时段")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.text)
                        Text("23:00 – 08:00 不推送")
                            .font(.system(size: 11.5))
                            .foregroundColor(Palette.sub)
                    }
                    Spacer()
                    Toggle("", isOn: $store.settings.quietHours)
                        .labelsHidden()
                        .tint(Palette.green)
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
            }
        }
        .onChange(of: store.settings.billPush) { _ in
            store.save()
            Notifier.shared.refresh(store: store)
        }
        .onChange(of: store.settings.actPush) { _ in
            store.save()
            Notifier.shared.refresh(store: store)
        }
        .onChange(of: store.settings.quietHours) { _ in
            store.save()
        }
    }

    // MARK: 卡片管理

    private var cardManageList: some View {
        CardShell {
            VStack(spacing: 0) {
                ForEach(Array(store.cards.enumerated()), id: \.offset) { index, card in
                    Button {
                        editing = card
                    } label: {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(LinearGradient(colors: [Color(hex: card.colorA), Color(hex: card.colorB)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(String(card.short.prefix(1)))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(card.bank + " ••" + card.last4)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Palette.text)
                                Text("账单日 \(card.billDay) 日 · 还款日 \(card.dueDay) 日 · " +
                                     (card.remind ? "提前 \(card.remindDays) 天提醒" : "未开启提醒"))
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Palette.sub)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(Color(hex: "C7C7CC"))
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 13)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if index < store.cards.count - 1 {
                        RowDivider(inset: 59)
                    }
                }
            }
        }
    }

    // MARK: 其他

    private var otherCard: some View {
        CardShell {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    IconBadge(text: "重", color: Palette.red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("重置演示数据")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.text)
                        Text("恢复为初始示例，谨慎操作")
                            .font(.system(size: 11.5))
                            .foregroundColor(Palette.sub)
                    }
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
                .contentShape(Rectangle())
                .onTapGesture { confirmReset = true }

                RowDivider(inset: 48)

                HStack(spacing: 12) {
                    IconBadge(text: "版", color: Color(hex: "8E8E93"))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("版本")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Palette.text)
                        Text("1.0 · 本地存储，数据不上传")
                            .font(.system(size: 11.5))
                            .foregroundColor(Palette.sub)
                    }
                    Spacer()
                }
                .padding(.horizontal, 15)
                .padding(.vertical, 13)
            }
        }
    }
}

// MARK: - 卡片编辑

struct CardEditorView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss

    @State private var card: CreditCard
    private let isNew: Bool

    @State private var confirmDelete = false
    @State private var showError = false

    init(card: CreditCard, isNew: Bool = false) {
        _card = State(initialValue: card)
        self.isNew = isNew
    }

    private var organizations: [String] { ["银联", "VISA", "Mastercard", "AE", "JCB"] }

    var body: some View {
        NavigationStack {
            Form {
                Section("卡片信息") {
                    TextField("银行名称，如 招商银行", text: $card.bank)
                    TextField("卡片名称，如 经典白金卡", text: $card.name)
                    Picker("卡组织", selection: $card.org) {
                        ForEach(organizations, id: \.self) { org in
                            Text(org).tag(org)
                        }
                    }
                    HStack {
                        Text("卡号后四位")
                        Spacer()
                        TextField("0000", text: $card.last4)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }
                }

                Section("额度") {
                    HStack {
                        Text("信用额度")
                        Spacer()
                        TextField("30000", value: $card.limit, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("已用额度")
                        Spacer()
                        TextField("0", value: $card.used, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    HStack {
                        Text("本期已还")
                        Spacer()
                        TextField("0", value: $card.paid, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                }

                Section("账单周期") {
                    Picker("账单日（出账日）", selection: $card.billDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("每月 \(day) 日").tag(day)
                        }
                    }
                    Picker("还款日", selection: $card.dueDay) {
                        ForEach(1...28, id: \.self) { day in
                            Text("每月 \(day) 日").tag(day)
                        }
                    }
                }

                Section("提醒") {
                    Toggle("还款提醒", isOn: $card.remind)
                        .tint(Palette.green)
                    if card.remind {
                        Picker("提前天数", selection: $card.remindDays) {
                            ForEach([1, 2, 3, 5, 7], id: \.self) { d in
                                Text("提前 \(d) 天").tag(d)
                            }
                        }
                    }
                }

                Section {
                    Text("账单日与还款日相差 18–25 天较常见。修改后会按新日期重新计算提醒。")
                        .font(.system(size: 12))
                        .foregroundColor(Palette.sub)
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Text("删除这张卡").frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .navigationTitle(isNew ? "添加卡片" : "编辑卡片")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .alert("请填写银行名称", isPresented: $showError) {
                Button("好", role: .cancel) { }
            }
            .alert("删除这张卡？", isPresented: $confirmDelete) {
                Button("删除", role: .destructive) {
                    store.deleteCard(card.id)
                    Notifier.shared.refresh(store: store)
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            }
        }
    }

    private func save() {
        let bank = card.bank.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !bank.isEmpty else {
            showError = true
            return
        }

        card.bank = bank
        if card.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            card.name = "信用卡"
        }
        if card.last4.count > 4 {
            card.last4 = String(card.last4.suffix(4))
        }
        if card.last4.isEmpty {
            card.last4 = "0000"
        }
        if card.limit < 1 {
            card.limit = 1
        }

        if let index = store.cards.firstIndex(where: { $0.id == card.id }) {
            store.cards[index] = card
        } else {
            store.cards.append(card)
        }

        store.save()
        Notifier.shared.refresh(store: store)
        dismiss()
    }
}

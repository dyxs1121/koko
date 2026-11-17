import SwiftUI

struct ActivitiesView: View {
    @EnvironmentObject var store: Store

    enum Scope: String, CaseIterable {
        case all, doing, done
    }

    @State private var scope: Scope = .all
    @State private var detail: Activity?
    @State private var adding = false

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    statsRow
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    segmented
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                    list
                        .padding(.horizontal, 20)
                        .padding(.top, 14)
                        .padding(.bottom, 18)
                }
            }
        }
        .sheet(item: $detail) { act in
            ActivityDetailView(activityID: act.id).environmentObject(store)
        }
        .sheet(isPresented: $adding) {
            ActivityEditorView().environmentObject(store)
        }
    }

    // MARK: 头部

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(Fmt.todayLine())
                    .font(.system(size: 12.5))
                    .foregroundColor(Palette.sub)
                Text("活动与权益")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundColor(Palette.text)
            }

            Spacer()

            Button {
                adding = true
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

    // MARK: 概览

    private var doingCount: Int { store.activities.filter { !$0.isDone }.count }
    private var doneCount: Int { store.activities.filter { $0.isDone }.count }

    private var statsRow: some View {
        HStack(spacing: 11) {
            VStack(alignment: .leading, spacing: 4) {
                Text("进行中")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(doingCount)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Palette.text)
                    Text("个")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.sub)
                }
                Text(nearestHint)
                    .font(.system(size: 10.5))
                    .foregroundColor(Palette.orange)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("已完成")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(doneCount)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(Palette.green)
                    Text("个")
                        .font(.system(size: 11))
                        .foregroundColor(Palette.sub)
                }
                Text("本月累计打卡")
                    .font(.system(size: 10.5))
                    .foregroundColor(Palette.sub)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var nearestHint: String {
        let pending = store.activities.filter { !$0.isDone }
        guard let first = pending.min(by: { $0.deadline < $1.deadline }) else {
            return "暂无待办"
        }
        let left = max(0, DateHelp.daysToDeadline(first.deadline))
        return "最近截止剩 \(left) 天"
    }

    // MARK: 分段

    private var segmented: some View {
        HStack(spacing: 2) {
            ForEach(Scope.allCases, id: \.self) { item in
                Button {
                    scope = item
                } label: {
                    Text(scopeLabel(item))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(scope == item ? Palette.text : Color(hex: "6C6C70"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(scope == item ? Color.white : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(Color(hex: "767680").opacity(0.10))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func scopeLabel(_ item: Scope) -> String {
        switch item {
        case .all: return "全部 \(store.activities.count)"
        case .doing: return "进行中 \(doingCount)"
        case .done: return "已完成 \(doneCount)"
        }
    }

    // MARK: 列表

    private var filtered: [Activity] {
        switch scope {
        case .all: return store.activities
        case .doing: return store.activities.filter { !$0.isDone }
        case .done: return store.activities.filter { $0.isDone }
        }
    }

    private var list: some View {
        VStack(spacing: 11) {
            if filtered.isEmpty {
                VStack(spacing: 6) {
                    Text("这里还没有活动")
                        .font(.system(size: 13))
                        .foregroundColor(Color(hex: "A0A0A5"))
                    Text("点右上角 + 添加一个")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "A0A0A5").opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 46)
            } else {
                ForEach(filtered) { act in
                    activityCard(act)
                }
            }
        }
    }

    private func activityCard(_ act: Activity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                PillView(text: store.cardName(act.cardID), fg: Color(hex: "5A48E0"), bg: Palette.purple.opacity(0.10))
                PillView(text: act.kind.shortLabel, fg: Palette.blue, bg: Palette.blue.opacity(0.09))
                if act.isDone {
                    PillView(text: "已完成", fg: Palette.green, bg: Palette.green.opacity(0.12))
                }
                Spacer()
            }
            .padding(.bottom, 6)

            Text(act.title)
                .font(.system(size: 14.5, weight: .semibold))
                .foregroundColor(Palette.text)

            Text(act.detail)
                .font(.system(size: 11.5))
                .foregroundColor(Palette.sub)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 3)

            HStack {
                Text(progressLabel(act))
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
                Spacer()
                Text(act.percentText)
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
            }
            .padding(.top, 11)
            .padding(.bottom, 5)

            BarView(value: act.ratio, height: 6,
                    tint: act.isDone
                    ? LinearGradient(colors: [Palette.green, Color(hex: "5BD98A")], startPoint: .leading, endPoint: .trailing)
                    : Palette.accentGradient)

            HStack(spacing: 5) {
                Image(systemName: "bell")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(Palette.sub)

                Text(act.remind.rawValue + " · 剩 \(max(0, DateHelp.daysToDeadline(act.deadline))) 天")
                    .font(.system(size: 11))
                    .foregroundColor(daysColor(act))

                Spacer()

                checkButton(act)
            }
            .padding(.top, 12)
        }
        .padding(15)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 1.5, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture { detail = act }
    }

    private func daysColor(_ act: Activity) -> Color {
        let left = DateHelp.daysToDeadline(act.deadline)
        return (!act.isDone && left <= 3) ? Palette.red : Palette.sub
    }

    private func progressLabel(_ act: Activity) -> String {
        if act.kind == .amount {
            return "进度 " + Fmt.yuan(act.value) + " / " + Fmt.yuan(act.target)
        }
        return "进度 \(Int(act.value)) / \(Int(act.target)) 次"
    }

    private func checkButton(_ act: Activity) -> some View {
        Button {
            if act.isDone {
                store.undoLastStep(activityID: act.id)
                Notifier.shared.refresh(store: store)
            } else if act.kind == .amount {
                detail = act
            } else {
                store.checkNextStep(activityID: act.id)
                Notifier.shared.refresh(store: store)
            }
        } label: {
            Text(buttonTitle(act))
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(act.isDone ? Color(hex: "1E9E4C") : Palette.blue)
                .padding(.horizontal, 13)
                .padding(.vertical, 7)
                .background(act.isDone ? Palette.green.opacity(0.12) : Palette.blue.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func buttonTitle(_ act: Activity) -> String {
        if act.isDone { return "已完成" }
        switch act.kind {
        case .amount: return "记一笔"
        case .count: return "打卡 +1"
        case .once: return "确认完成"
        }
    }
}

// MARK: - 活动详情

struct ActivityDetailView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss

    let activityID: UUID

    @State private var amountText = ""
    @State private var confirmDelete = false

    private var activity: Activity? {
        store.activities.first { $0.id == activityID }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Palette.bg.ignoresSafeArea()

                if let act = activity {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            tagRow(act)
                            Text(act.title)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(Palette.text)
                                .padding(.top, 9)
                            Text(act.detail)
                                .font(.system(size: 12.5))
                                .foregroundColor(Palette.sub)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 7)

                            progressPanel(act)
                                .padding(.top, 16)

                            if act.kind == .amount {
                                amountInput(act)
                            } else {
                                stepList(act)
                            }

                            actionRow(act)
                                .padding(.top, 20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle("活动详情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Palette.text)
                            .frame(width: 30, height: 30)
                            .background(Color(hex: "767680").opacity(0.14))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .alert("删除这个活动？", isPresented: $confirmDelete) {
                Button("删除", role: .destructive) {
                    store.deleteActivity(activityID)
                    Notifier.shared.refresh(store: store)
                    dismiss()
                }
                Button("取消", role: .cancel) { }
            }
        }
    }

    private func tagRow(_ act: Activity) -> some View {
        HStack(spacing: 6) {
            PillView(text: store.cardName(act.cardID), fg: Color(hex: "5A48E0"), bg: Palette.purple.opacity(0.10))
            PillView(text: act.kind.label, fg: Palette.blue, bg: Palette.blue.opacity(0.09))
            if act.isDone {
                PillView(text: "已完成", fg: Palette.green, bg: Palette.green.opacity(0.12))
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private func progressPanel(_ act: Activity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(act.kind == .amount ? "累计消费" : "完成进度")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.sub)
                Spacer()
                Text(valueText(act))
                    .font(.system(size: 23, weight: .bold))
                    .foregroundColor(Palette.text)
            }

            BarView(value: act.ratio, height: 8,
                    tint: act.isDone
                    ? LinearGradient(colors: [Palette.green, Color(hex: "5BD98A")], startPoint: .leading, endPoint: .trailing)
                    : Palette.accentGradient)
                .padding(.top, 11)

            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "bell")
                        .font(.system(size: 10))
                        .foregroundColor(Palette.sub)
                    Text(act.remind.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(Palette.sub)
                }
                Spacer()
                Text("截止 " + Fmt.monthDay(act.deadline) + " · 剩 \(max(0, DateHelp.daysToDeadline(act.deadline))) 天")
                    .font(.system(size: 11))
                    .foregroundColor(Palette.sub)
            }
            .padding(.top, 10)
        }
        .padding(16)
        .background(Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func valueText(_ act: Activity) -> String {
        if act.kind == .amount {
            return Fmt.yuan(act.value) + " / " + Fmt.yuan(act.target)
        }
        return "\(Int(act.value)) / \(Int(act.target)) 次"
    }

    private func amountInput(_ act: Activity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("记录一笔消费")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Palette.sub)
                .padding(.leading, 3)
                .padding(.top, 18)
                .padding(.bottom, 7)

            HStack(spacing: 10) {
                TextField("0.00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 15))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Palette.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                Button {
                    let v = Double(amountText) ?? 0
                    guard v > 0 else { return }
                    store.addAmount(activityID: activityID, amount: v)
                    Notifier.shared.refresh(store: store)
                    amountText = ""
                } label: {
                    Text("记录")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Palette.blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 13)
                        .background(Palette.blue.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }

            Text("已累计 " + Fmt.money(act.current) + "，还差 " + Fmt.money(max(0, act.target - act.current)) + " 达标")
                .font(.system(size: 11))
                .foregroundColor(Color(hex: "A0A0A5"))
                .padding(.top, 7)
                .padding(.leading, 3)
        }
    }

    private func stepList(_ act: Activity) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("完成情况（点击勾选）")
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(Palette.sub)
                .padding(.leading, 3)
                .padding(.top, 18)
                .padding(.bottom, 7)

            CardShell {
                VStack(spacing: 0) {
                    ForEach(Array(act.steps.enumerated()), id: \.offset) { index, step in
                        Button {
                            store.toggleStep(activityID: activityID, index: index)
                            Notifier.shared.refresh(store: store)
                        } label: {
                            HStack(spacing: 11) {
                                ZStack {
                                    Circle()
                                        .stroke(step.done ? Palette.green : Color(hex: "D6D6DA"), lineWidth: 1.8)
                                        .frame(width: 22, height: 22)
                                    if step.done {
                                        Circle()
                                            .fill(Palette.green)
                                            .frame(width: 22, height: 22)
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }

                                Text(step.label)
                                    .font(.system(size: 13.5))
                                    .foregroundColor(step.done ? Color(hex: "A0A0A5") : Palette.text)
                                    .strikethrough(step.done, color: Color(hex: "A0A0A5"))

                                Spacer()
                            }
                            .padding(.horizontal, 15)
                            .padding(.vertical, 13)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < act.steps.count - 1 {
                            RowDivider(inset: 48)
                        }
                    }
                }
            }
        }
    }

    private func actionRow(_ act: Activity) -> some View {
        HStack(spacing: 10) {
            Button {
                confirmDelete = true
            } label: {
                Text("删除")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Palette.red)
                    .frame(width: 88)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            if act.isDone {
                Button {
                    store.setDone(activityID: activityID, done: false)
                    Notifier.shared.refresh(store: store)
                } label: {
                    Text("撤销完成")
                        .font(.system(size: 15.5, weight: .semibold))
                        .foregroundColor(Palette.sub)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color(hex: "E8E8ED"))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            } else {
                PrimaryButton(title: "标记为已完成") {
                    store.setDone(activityID: activityID, done: true)
                    Notifier.shared.refresh(store: store)
                }
            }
        }
    }
}

// MARK: - 添加活动

struct ActivityEditorView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var detail = ""
    @State private var cardID: UUID?
    @State private var kind: ActivityKind = .count
    @State private var targetText = "3"
    @State private var deadline = Date().addingTimeInterval(86400 * 14)
    @State private var remind: RemindRule = .weeklySunday
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("活动信息") {
                    TextField("活动名称，如 周五满 100 减 50", text: $title)
                    TextField("规则 / 名额 / 注意事项", text: $detail)
                    Picker("关联卡片", selection: Binding(
                        get: { cardID ?? store.cards.first?.id ?? UUID() },
                        set: { cardID = $0 }
                    )) {
                        ForEach(store.cards) { c in
                            Text(c.bank + " ••" + c.last4).tag(c.id)
                        }
                    }
                }

                Section("目标") {
                    Picker("目标类型", selection: $kind) {
                        ForEach(ActivityKind.allCases) { k in
                            Text(k.label).tag(k)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text(kind == .amount ? "目标金额" : "目标次数")
                        Spacer()
                        TextField("0", text: $targetText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }

                    DatePicker("截止日期", selection: $deadline, displayedComponents: .date)
                }

                Section("提醒") {
                    Picker("提醒方式", selection: $remind) {
                        ForEach(RemindRule.allCases) { r in
                            Text(r.rawValue).tag(r)
                        }
                    }
                }

                Section {
                    Text("按次数会自动生成可逐个打卡的清单；按金额每次记录消费累加；单次可一键确认完成。")
                        .font(.system(size: 12))
                        .foregroundColor(Palette.sub)
                }

                Section {
                    Button {
                        save()
                    } label: {
                        Text("添加活动")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                    }
                    .listRowBackground(Palette.primaryButton)
                }
            }
            .navigationTitle("添加活动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear {
                if cardID == nil { cardID = store.cards.first?.id }
            }
            .alert("请填写活动名称和目标值", isPresented: $showError) {
                Button("好", role: .cancel) { }
            }
        }
    }

    private func save() {
        let name = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let raw = Double(targetText) ?? 0
        guard !name.isEmpty, raw > 0, let cid = cardID else {
            showError = true
            return
        }

        let target = kind == .amount ? raw : max(1, raw.rounded())
        var steps: [ActivityStep] = []
        if kind != .amount {
            for i in 0..<Int(target) {
                steps.append(ActivityStep(label: "第 \(i + 1) 次", done: false))
            }
        }

        let act = Activity(cardID: cid,
                           title: name,
                           detail: detail.isEmpty ? (kind == .amount ? "累计消费达标即完成" : "按次打卡完成") : detail,
                           kind: kind,
                           target: target,
                           deadline: deadline,
                           remind: remind,
                           steps: steps)

        store.activities.append(act)
        store.save()
        Notifier.shared.refresh(store: store)
        dismiss()
    }
}

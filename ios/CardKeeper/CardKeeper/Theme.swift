import SwiftUI

// MARK: - 颜色

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let r: Double
        let g: Double
        let b: Double
        if cleaned.count == 3 {
            r = Double((value >> 8) & 0xF) / 15
            g = Double((value >> 4) & 0xF) / 15
            b = Double(value & 0xF) / 15
        } else {
            r = Double((value >> 16) & 0xFF) / 255
            g = Double((value >> 8) & 0xFF) / 255
            b = Double(value & 0xFF) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}

enum Palette {
    static let bg = Color(hex: "F2F2F7")
    static let surface = Color.white
    static let text = Color(hex: "111114")
    static let sub = Color(hex: "8A8A8E")
    static let faint = Color(hex: "B4B4B9")
    static let line = Color.black.opacity(0.06)
    static let blue = Color(hex: "0A84FF")
    static let green = Color(hex: "2CC15D")
    static let orange = Color(hex: "FF9F0A")
    static let red = Color(hex: "FF453A")
    static let purple = Color(hex: "6E5BFF")

    static let accentGradient = LinearGradient(
        colors: [Color(hex: "6E8BFF"), Color(hex: "9B7BFF")],
        startPoint: .leading, endPoint: .trailing)

    static let darkGradient = LinearGradient(
        colors: [Color(hex: "161821"), Color(hex: "232738"), Color(hex: "2E3348")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static let primaryButton = LinearGradient(
        colors: [Color(hex: "3D7BFF"), Color(hex: "5B4BFF")],
        startPoint: .topLeading, endPoint: .bottomTrailing)

    static func category(_ name: String) -> Color {
        switch name {
        case "餐饮": return Color(hex: "FF9F0A")
        case "购物": return Color(hex: "6E5BFF")
        case "加油": return Color(hex: "FF6B4A")
        case "超市": return Color(hex: "2CC15D")
        case "交通": return Color(hex: "0A84FF")
        case "订阅": return Color(hex: "5AC8FA")
        case "娱乐": return Color(hex: "FF4F8B")
        default: return Color(hex: "8E8E93")
        }
    }
}

// MARK: - 格式化

enum Fmt {
    private static let moneyFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    private static let yuanFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 0
        return f
    }()

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "MM-dd"
        return f
    }()

    private static let monthDayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "MM/dd"
        return f
    }()

    private static let todayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日 EEEE"
        return f
    }()

    static func money(_ v: Double) -> String { "¥" + (moneyFormatter.string(from: NSNumber(value: v)) ?? "0.00") }
    static func yuan(_ v: Double) -> String { "¥" + (yuanFormatter.string(from: NSNumber(value: v)) ?? "0") }
    static func raw(_ v: Double) -> String { moneyFormatter.string(from: NSNumber(value: v)) ?? "0.00" }
    static func dayLabel(_ d: Date) -> String { dayFormatter.string(from: d) }
    static func monthDay(_ d: Date) -> String { monthDayFormatter.string(from: d) }
    static func todayLine() -> String { todayFormatter.string(from: Date()) }
}

// MARK: - 通用组件

struct SectionHeader: View {
    var title: String
    var trailing: String = ""

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Palette.text)
            Spacer()
            Text(trailing)
                .font(.system(size: 12.5))
                .foregroundColor(Palette.sub)
        }
        .padding(.top, 26)
        .padding(.bottom, 11)
    }
}

struct BarView: View {
    var value: Double
    var height: CGFloat = 6
    var tint: LinearGradient = Palette.accentGradient

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "787880").opacity(0.14))
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

struct PillView: View {
    var text: String
    var fg: Color
    var bg: Color

    var body: some View {
        Text(text)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(bg)
            .clipShape(Capsule())
            .fixedSize()
    }
}

struct IconBadge: View {
    var text: String
    var color: Color
    var size: CGFloat = 32

    var body: some View {
        Text(text)
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundColor(color)
            .frame(width: size, height: size)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

struct RowDivider: View {
    var inset: CGFloat = 52

    var body: some View {
        Rectangle()
            .fill(Palette.line)
            .frame(height: 0.5)
            .padding(.leading, inset)
    }
}

struct CardShell<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .background(Palette.surface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: Color.black.opacity(0.04), radius: 1.5, x: 0, y: 1)
    }
}

struct PrimaryButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15.5, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(Palette.primaryButton)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .shadow(color: Color(hex: "3C5AFF").opacity(0.32), radius: 12, x: 0, y: 8)
    }
}

// MARK: - 卡面

struct CardFace: View {
    var card: CreditCard
    var height: CGFloat = 180

    private var background: LinearGradient {
        LinearGradient(colors: [Color(hex: card.colorA), Color(hex: card.colorB)],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            topRow
            Spacer(minLength: 6)
            middleRow
            Spacer(minLength: 6)
            bottomRow
        }
        .padding(17)
        .frame(height: height)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.20), radius: 14, x: 0, y: 10)
    }

    private var topRow: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.16))
                .frame(width: 26, height: 26)
                .overlay(
                    Text(String(card.short.prefix(1)))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 1) {
                Text(card.bank)
                    .font(.system(size: 13.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(card.name)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Text(card.org)
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    private var middleRow: some View {
        HStack(spacing: 8) {
            Text("•••• •••• •••• " + card.last4)
                .font(.system(size: 12.5, weight: .medium))
                .foregroundColor(.white.opacity(0.82))
                .lineLimit(1)
                .fixedSize()

            Spacer(minLength: 4)

            Text(card.dueLabel)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(card.isCleared ? Color(hex: "9BE8B4") : Color(hex: "FFCF8A"))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(card.isCleared ? Color(hex: "2CC15D").opacity(0.20) : Color(hex: "FF9F0A").opacity(0.20))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .fixedSize()
        }
    }

    private var bottomRow: some View {
        HStack(spacing: 0) {
            infoCell("账单日", "每月 \(card.billDay) 日")
            infoCell("还款日", "每月 \(card.dueDay) 日")
            infoCell("本期应还", card.isCleared ? "¥0" : Fmt.yuan(card.outstanding))
        }
    }

    private func infoCell(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.5))
            Text(value)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

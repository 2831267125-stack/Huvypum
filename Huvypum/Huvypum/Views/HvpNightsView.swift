import SwiftUI

struct HvpNightsView: View {
    @EnvironmentObject private var stage: HvpStageStore

    private var nights: [HvpNight] { HvpNightBook.nights }
    private var featured: HvpNight? { nights.first }
    private var rest: [HvpNight] {
        Array(nights.dropFirst())
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HvpNightsHeader()

                if let featured {
                    NavigationLink(destination: HvpNightDetailView(night: featured)) {
                        HvpNightFeaturedBill(
                            night: featured,
                            takeCount: stage.clips(inNight: featured.id).count
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                HStack(spacing: 8) {
                    Capsule()
                        .fill(HvpPalette.teal)
                        .frame(width: 28, height: 4)
                    Text("Tonight's doors")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(HvpPalette.mute)
                    Spacer()
                }

                VStack(spacing: 0) {
                    ForEach(Array(rest.enumerated()), id: \.element.id) { index, night in
                        NavigationLink(destination: HvpNightDetailView(night: night)) {
                            HvpNightScheduleRow(
                                night: night,
                                takeCount: stage.clips(inNight: night.id).count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())

                        if index < rest.count - 1 {
                            Rectangle()
                                .fill(HvpPalette.line)
                                .frame(height: 1)
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(HvpPalette.plate)
                .cornerRadius(18)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(HvpPalette.line, lineWidth: 1)
                )
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Nights", displayMode: .inline)
    }
}

struct HvpNightsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Nights")
                .font(.largeTitle.weight(.bold))
            Text("A door sheet for venue bills. Pick a room, then open the takes from that night.")
                .font(.subheadline)
                .foregroundColor(HvpPalette.mute)
        }
    }
}

struct HvpNightFeaturedBill: View {
    let night: HvpNight
    let takeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(uiImage: HvpCoverArt.resolved(night.coverAsset))
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 168)
                .clipped()

            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 2) {
                    Text("DOORS")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(HvpPalette.teal)
                    Text(night.doors)
                        .font(.title3.weight(.bold))
                        .foregroundColor(HvpPalette.ink)
                        .monospacedDigit()
                }
                .frame(width: 64)

                Rectangle()
                    .fill(HvpPalette.teal)
                    .frame(width: 3)
                    .cornerRadius(2)

                VStack(alignment: .leading, spacing: 4) {
                    Text(night.city.uppercased())
                        .font(.caption.weight(.bold))
                        .foregroundColor(HvpPalette.teal)
                    Text(night.venue)
                        .font(.title3.weight(.bold))
                        .foregroundColor(HvpPalette.ink)
                        .multilineTextAlignment(.leading)
                    Text(night.bill)
                        .font(.subheadline)
                        .foregroundColor(HvpPalette.mute)
                    Text("\(night.capacity) cap · \(takeCount) takes")
                        .font(.caption)
                        .foregroundColor(HvpPalette.mute)
                }
                Spacer(minLength: 0)
            }
            .padding(14)
        }
        .background(HvpPalette.plate)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(HvpPalette.teal.opacity(0.35), lineWidth: 1.5)
        )
        .clipped()
    }
}

struct HvpNightScheduleRow: View {
    let night: HvpNight
    let takeCount: Int

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(spacing: 2) {
                Text(night.doors)
                    .font(.headline.weight(.bold))
                    .foregroundColor(HvpPalette.ink)
                    .monospacedDigit()
                Text(night.city)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(HvpPalette.teal)
                    .lineLimit(1)
            }
            .frame(width: 60)

            Rectangle()
                .fill(HvpPalette.line)
                .frame(width: 1, height: 52)

            VStack(alignment: .leading, spacing: 3) {
                Text(night.venue)
                    .font(.headline)
                    .foregroundColor(HvpPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(night.bill)
                    .font(.caption)
                    .foregroundColor(HvpPalette.mute)
                    .lineLimit(1)
                Text("\(night.capacity) cap · \(takeCount) takes")
                    .font(.caption2)
                    .foregroundColor(HvpPalette.mute)
            }

            Spacer(minLength: 8)

            Image(uiImage: HvpCoverArt.resolved(night.coverAsset))
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}

struct HvpNightDetailView: View {
    @EnvironmentObject private var stage: HvpStageStore
    let night: HvpNight

    private var takes: [HvpClip] {
        stage.clips(inNight: night.id)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(uiImage: HvpCoverArt.resolved(night.coverAsset))
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(18)

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(night.city.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundColor(HvpPalette.teal)
                        Text(night.venue)
                            .font(.largeTitle.weight(.bold))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("DOORS")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(HvpPalette.mute)
                        Text(night.doors)
                            .font(.title2.weight(.bold))
                            .monospacedDigit()
                    }
                }

                Text(night.bill)
                    .font(.title3.weight(.semibold))
                Text(night.blurb)
                    .foregroundColor(HvpPalette.mute)
                Text("\(night.capacity) capacity · \(takes.count) takes on this bill")
                    .font(.caption)
                    .foregroundColor(HvpPalette.mute)

                HStack(spacing: 8) {
                    Capsule()
                        .fill(HvpPalette.teal)
                        .frame(width: 28, height: 4)
                    Text("Takes from this night")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(HvpPalette.mute)
                    Spacer()
                }
                .padding(.top, 4)

                if takes.isEmpty {
                    Text("No takes posted for this bill yet.")
                        .font(.subheadline)
                        .foregroundColor(HvpPalette.mute)
                        .padding(.vertical, 8)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(takes.enumerated()), id: \.element.id) { index, clip in
                            NavigationLink(destination: HvpClipDetailView(clipId: clip.id)) {
                                HvpNightTakeRow(clip: clip)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if index < takes.count - 1 {
                                Rectangle()
                                    .fill(HvpPalette.line)
                                    .frame(height: 1)
                                    .padding(.leading, 84)
                            }
                        }
                    }
                    .background(HvpPalette.plate)
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(HvpPalette.line, lineWidth: 1)
                    )
                }
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle(night.city, displayMode: .inline)
    }
}

struct HvpNightTakeRow: View {
    let clip: HvpClip

    var body: some View {
        HStack(spacing: 12) {
            Image(uiImage: HvpCoverArt.resolved(clip.coverAsset))
                .resizable()
                .scaledToFill()
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(clip.title)
                    .font(.headline)
                    .foregroundColor(HvpPalette.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                Text(clip.author)
                    .font(.caption)
                    .foregroundColor(HvpPalette.mute)
                Text(clip.durationLabel)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(HvpPalette.teal)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(HvpPalette.mute)
        }
        .padding(12)
        .contentShape(Rectangle())
    }
}

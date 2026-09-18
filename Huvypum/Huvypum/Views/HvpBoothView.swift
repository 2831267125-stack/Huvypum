import SwiftUI
import AVFoundation

struct HvpBoothView: View {
    @EnvironmentObject private var appStore: HvpAppStore
    @EnvironmentObject private var stage: HvpStageStore
    @EnvironmentObject private var store: HvpStoreManager
    @StateObject private var capture = HvpCaptureEngine()
    @State private var title = ""
    @State private var caption = ""
    @State private var nightId = "n01"
    @State private var category: HvpCategory = .indie
    @State private var coverAsset = "HvpPickerA"
    @State private var pickedURL: URL?
    @State private var kind: HvpMediaKind = .video
    @State private var durationLabel = "0:12"
    @State private var showPhotos = false
    @State private var showCamera = false
    @State private var voiceText = ""
    @State private var goPreview = false
    @State private var draftId = UUID().uuidString

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Booth")
                    .font(.largeTitle.weight(.bold))
                Text("Attach a performance take, write a liner note, then preview. Saving spends \(HvpAppCopy.saveCost) Spotlight.")
                    .foregroundColor(HvpPalette.mute)

                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .cornerRadius(22)

                Button("Photos") { showPhotos = true }
                    .buttonStyle(HvpSecondaryButtonStyle())
                Button("Record") {
                    HvpCameraMicPermission.requestCamera { ok in
                        guard ok else {
                            capture.status = "Camera is not available. You can still choose Photos."
                            return
                        }
                        HvpCameraMicPermission.requestMic { micOK in
                            showCamera = true
                            capture.prepareCamera(includeAudio: micOK, thenRecord: false)
                            if !micOK {
                                capture.status = "Sound is off for this take. Allow the microphone to record the room."
                            }
                        }
                    }
                }
                .buttonStyle(HvpSecondaryButtonStyle())

                if showCamera {
                    HvpCameraPreview(layer: capture.previewLayer)
                        .frame(height: 280)
                        .cornerRadius(18)
                    if capture.isRecording {
                        Button("Stop") { capture.stopMovie() }
                            .buttonStyle(HvpPrimaryButtonStyle())
                    } else {
                        Button("Start recording") { capture.startMovie() }
                            .buttonStyle(HvpPrimaryButtonStyle())
                    }
                    if capture.lastFileURL != nil {
                        Button("Use current clip") {
                            pickedURL = capture.lastFileURL
                            kind = .video
                            durationLabel = "0:\(max(capture.seconds, 1))"
                            coverAsset = "HvpPickerB"
                            showCamera = false
                            capture.shutdown()
                        }
                        .buttonStyle(HvpTealButtonStyle())
                    }
                }

                if !capture.status.isEmpty {
                    Text(capture.status).foregroundColor(HvpPalette.rose).font(.footnote)
                }

                TextField("Title", text: $title)
                    .padding(12)
                    .background(HvpPalette.plate)
                    .cornerRadius(12)
                TextField("Liner note caption", text: $caption)
                    .padding(12)
                    .background(HvpPalette.plate)
                    .cornerRadius(12)

                Button("Voice note") {
                    HvpCameraMicPermission.requestMic { ok in
                        if ok {
                            voiceText = ""
                            showCamera = false
                            capture.startVoice()
                        } else {
                            voiceText = "Voice note is unavailable. You can still type the liner note."
                        }
                    }
                }
                .buttonStyle(HvpSecondaryButtonStyle())
                .disabled(capture.isVoiceMode)

                if capture.isVoiceMode {
                    HStack(spacing: 3) {
                        ForEach(Array(capture.levels.enumerated()), id: \.offset) { bar in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(HvpPalette.violet)
                                .frame(width: 6, height: max(4, bar.element * 54))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .background(HvpPalette.plate)
                    .cornerRadius(14)
                    Text("Recording a spoken liner — \(clockLabel(capture.seconds))")
                        .font(.footnote)
                        .foregroundColor(HvpPalette.mute)
                    Button("Stop voice note") { finishVoiceNote() }
                        .buttonStyle(HvpPrimaryButtonStyle())
                }

                if !voiceText.isEmpty {
                    Text(voiceText).font(.footnote).foregroundColor(HvpPalette.mute)
                }

                Picker("Night", selection: $nightId) {
                    ForEach(HvpNightBook.nights) { night in
                        Text(night.venue).tag(night.id)
                    }
                }
                .pickerStyle(MenuPickerStyle())

                Picker("Bill", selection: $category) {
                    ForEach(HvpCategory.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())

                Button("Save draft") { persistDraft() }
                    .buttonStyle(HvpSecondaryButtonStyle())

                NavigationLink(destination: HvpPreviewView(draft: makeDraft()), isActive: $goPreview) {
                    EmptyView()
                }
                Button("Preview clip") {
                    persistDraft()
                    goPreview = true
                }
                .buttonStyle(HvpPrimaryButtonStyle())
                .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(18)
            .padding(.bottom, 28)
        }
        .background(HvpPalette.paper.ignoresSafeArea())
        .navigationBarTitle("Booth", displayMode: .inline)
        .sheet(isPresented: $showPhotos) {
            HvpClipPicker { url in
                showPhotos = false
                if let url {
                    pickedURL = url
                    kind = url.pathExtension.lowercased() == "jpg" ? .photo : .video
                    coverAsset = "HvpPickerA"
                    durationLabel = "0:18"
                }
            }
        }
        .onAppear { restoreDraft() }
        .onDisappear { capture.shutdown() }
    }

    private var previewImage: UIImage {
        HvpCoverArt.resolved(coverAsset)
    }

    private func clockLabel(_ seconds: Int) -> String {
        String(format: "0:%02d", max(seconds, 0))
    }

    private func finishVoiceNote() {
        let length = max(capture.seconds, 1)
        capture.stopVoice()
        guard let url = capture.lastFileURL else {
            voiceText = "That voice note did not save. Try Voice note again."
            return
        }
        if caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            caption = "Late set under violet lights — last chorus hit and the floor moved as one."
        }
        if pickedURL == nil {
            pickedURL = url
            kind = .audio
            durationLabel = clockLabel(length)
            voiceText = "Spoken liner attached (\(clockLabel(length))). Edit the words if needed."
        } else {
            voiceText = "Spoken liner recorded (\(clockLabel(length))). Your performance take stays attached."
        }
    }

    private func makeDraft() -> HvpDraft {
        HvpDraft(
            id: draftId,
            nightId: nightId,
            category: category,
            title: title.isEmpty ? "Untitled take" : title,
            caption: caption,
            coverAsset: coverAsset,
            fileName: persistMedia(),
            kind: kind,
            durationLabel: durationLabel,
            step: "preview"
        )
    }

    private func persistMedia() -> String? {
        guard let pickedURL else { return nil }
        if let dest = HvpMediaIO.persist(pickedURL, id: draftId) {
            return dest.lastPathComponent
        }
        return nil
    }

    private func persistDraft() {
        let draft = makeDraft()
        stage.saveDraft(draft)
    }

    private func restoreDraft() {
        guard let draft = stage.draft else { return }
        draftId = draft.id
        nightId = draft.nightId
        category = draft.category
        title = draft.title
        caption = draft.caption
        coverAsset = draft.coverAsset
        kind = draft.kind
        durationLabel = draft.durationLabel
    }
}

import AVFoundation
import UIKit
import SwiftUI

final class HvpCaptureEngine: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var isRecording = false
    @Published var seconds = 0
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var lastFileURL: URL?
    @Published var lastKind: HvpMediaKind = .video
    @Published var cameraReady = false
    @Published var isVoiceMode = false
    @Published var levels: [CGFloat] = Array(repeating: 0.12, count: 22)
    @Published var status = ""

    private let session = AVCaptureSession()
    private let movie = AVCaptureMovieFileOutput()
    private let queue = DispatchQueue(label: "hvp.capture")
    private var timer: Timer?
    private var audioRecorder: AVAudioRecorder?
    private var includeAudio = false
    private var position: AVCaptureDevice.Position = .back
    private var startedAt: Date?

    func prepareCamera(includeAudio: Bool, thenRecord: Bool) {
        self.includeAudio = includeAudio
        isVoiceMode = false
        status = ""
        lastFileURL = nil
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
            self.session.beginConfiguration()
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            if self.session.canSetSessionPreset(.high) {
                self.session.sessionPreset = .high
            }
            guard let cam = Self.videoDevice(for: self.position),
                  let video = try? AVCaptureDeviceInput(device: cam),
                  self.session.canAddInput(video) else {
                self.session.commitConfiguration()
                DispatchQueue.main.async {
                    self.cameraReady = false
                    self.status = "Camera is not available here. In Simulator use I/O → Camera, or import from Photos."
                }
                return
            }
            self.session.addInput(video)
            if self.session.canAddOutput(self.movie) {
                self.session.addOutput(self.movie)
            }
            self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async {
                let layer = AVCaptureVideoPreviewLayer(session: self.session)
                layer.videoGravity = .resizeAspectFill
                self.previewLayer = layer
                self.cameraReady = self.session.isRunning
                if thenRecord {
                    self.startMovie()
                } else if !self.session.isRunning {
                    self.status = "Camera is not available here. In Simulator use I/O → Camera, or import from Photos."
                }
            }
        }
    }

    func flipCamera() {
        guard !isRecording else { return }
        position = position == .front ? .back : .front
        prepareCamera(includeAudio: includeAudio, thenRecord: false)
    }

    func startMovie() {
        queue.async {
            guard self.session.isRunning, self.movie.connection(with: .video) != nil else {
                DispatchQueue.main.async {
                    self.status = "That take did not save. Try Record again."
                    self.isRecording = false
                }
                return
            }
            let url = HvpMediaIO.tempURL(ext: "mov")
            if self.includeAudio, self.movie.connection(with: .audio) == nil {
                if HvpCameraMicPermission.micAuthorized,
                   let mic = AVCaptureDevice.default(for: .audio),
                   let audio = try? AVCaptureDeviceInput(device: mic),
                   self.session.canAddInput(audio) {
                    self.session.beginConfiguration()
                    self.session.addInput(audio)
                    self.session.commitConfiguration()
                } else {
                    DispatchQueue.main.async {
                        self.status = "Sound is not available here, so this take records picture only."
                    }
                }
            }
            if self.movie.connection(with: .video)?.isVideoOrientationSupported == true {
                self.movie.connection(with: .video)?.videoOrientation = .portrait
            }
            if self.movie.connection(with: .video)?.isVideoMirroringSupported == true {
                self.movie.connection(with: .video)?.isVideoMirrored = self.position == .front
            }
            self.movie.startRecording(to: url, recordingDelegate: self)
            DispatchQueue.main.async {
                self.lastKind = .video
                self.isRecording = true
                self.seconds = 0
                self.pulse()
            }
        }
    }

    func stopMovie() {
        queue.async {
            guard self.movie.isRecording else { return }
            self.movie.stopRecording()
            DispatchQueue.main.async {
                self.isRecording = false
                self.timer?.invalidate()
            }
        }
    }

    func startVoice() {
        status = ""
        lastFileURL = nil
        queue.async {
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async {
                self.cameraReady = false
                self.previewLayer = nil
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.beginVoiceRecorder()
                }
            }
        }
    }

    private func beginVoiceRecorder() {
        let url = HvpMediaIO.tempURL(ext: "m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            status = "Microphone did not start. Try Voice note again."
            return
        }
        let recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.isMeteringEnabled = true
        recorder?.prepareToRecord()
        guard recorder?.record() == true else {
            status = "Microphone did not start. Try Voice note again."
            return
        }
        audioRecorder = recorder
        lastKind = .audio
        isVoiceMode = true
        isRecording = true
        seconds = 0
        pulse()
    }

    func stopVoice() {
        audioRecorder?.updateMeters()
        audioRecorder?.stop()
        let url = audioRecorder?.url
        audioRecorder = nil
        isRecording = false
        isVoiceMode = false
        timer?.invalidate()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        lastFileURL = url
    }

    func shutdown() {
        timer?.invalidate()
        queue.async {
            if self.movie.isRecording { self.movie.stopRecording() }
            if self.session.isRunning { self.session.stopRunning() }
        }
        audioRecorder?.stop()
        cameraReady = false
        isVoiceMode = false
        previewLayer = nil
        isRecording = false
    }

    private static func videoDevice(for position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        var types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera]
        if #available(iOS 17.0, *) {
            types.append(contentsOf: [.continuityCamera, .external])
        }
        let named = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: position).devices.first
        if let named { return named }
        let any = AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified).devices
        if position == .back {
            return any.first(where: { $0.position == .back }) ?? any.first ?? AVCaptureDevice.default(for: .video)
        }
        return any.first(where: { $0.position == .front }) ?? any.first ?? AVCaptureDevice.default(for: .video)
    }

    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        DispatchQueue.main.async {
            if error == nil {
                self.lastFileURL = outputFileURL
            } else {
                self.status = "That take did not save. Try Record again."
            }
        }
    }

    private func pulse() {
        timer?.invalidate()
        startedAt = Date()
        timer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.seconds = Int(Date().timeIntervalSince(self.startedAt ?? Date()))
            guard let rec = self.audioRecorder, rec.isRecording else { return }
            rec.updateMeters()
            let power = rec.averagePower(forChannel: 0)
            let norm = max(0.08, min(1, CGFloat((power + 55) / 45)))
            var next = self.levels
            if !next.isEmpty {
                next.removeFirst()
                next.append(norm)
                self.levels = next
            }
        }
    }
}

enum HvpMediaIO {
    static var root: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("HvpPhrases", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func tempURL(ext: String) -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("hvp-\(UUID().uuidString).\(ext)")
    }

    static func persist(_ src: URL, id: String) -> URL? {
        let dest = root.appendingPathComponent("\(id).\(src.pathExtension)")
        try? FileManager.default.removeItem(at: dest)
        do {
            try FileManager.default.copyItem(at: src, to: dest)
            return dest
        } catch {
            return nil
        }
    }

    static func remove(id: String) {
        let items = (try? FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil)) ?? []
        for item in items where item.deletingPathExtension().lastPathComponent == id {
            try? FileManager.default.removeItem(at: item)
        }
    }

    static func eraseAll() {
        try? FileManager.default.removeItem(at: root)
        _ = root
    }
}

final class HvpPreviewHost: UIView {
    var layerPreview: AVCaptureVideoPreviewLayer? {
        didSet {
            layer.sublayers?.forEach { $0.removeFromSuperlayer() }
            if let layerPreview {
                layerPreview.frame = bounds
                layer.addSublayer(layerPreview)
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layerPreview?.frame = bounds
    }
}

struct HvpCameraPreview: UIViewRepresentable {
    let layer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> HvpPreviewHost {
        let view = HvpPreviewHost()
        view.backgroundColor = .black
        view.layerPreview = layer
        return view
    }

    func updateUIView(_ uiView: HvpPreviewHost, context: Context) {
        uiView.layerPreview = layer
    }
}

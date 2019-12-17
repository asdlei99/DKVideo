
import Foundation
import GCDWebServer
import RxRelay
open class M3U8Downloader: NSObject {
    public let downloader = VideoDownloader()
    public let progress: BehaviorRelay<Float> = .init(value: 0.0)
    public var fileName = ""
    var directoryName: String {
        fileName.replacingOccurrences(of: ".m3u8", with: "")
    }

    public var m3u8URL = ""
    private let m3u8Parser = DKM3u8Helper()
    public var downloadStatus: BehaviorRelay<Status> = .init(value: .paused)

    public init(fileName: String, m3u8URL: String) {
        self.fileName = fileName
        self.m3u8URL = m3u8URL
        super.init()
        self.downloader.downloadStatus.bind(to: self.downloadStatus).disposed(by: self.rx.disposeBag)
        self.downloader.progress.bind(to: self.progress).disposed(by: self.rx.disposeBag)
    }

    open func parse() {
        m3u8Parser.parser(url: m3u8URL, name: fileName, success: { [weak self] _ in
            guard let self = self else { return }
            self.downloader.tsPlaylist = self.m3u8Parser.tsPlaylist
            self.downloader.m3u8Data = self.m3u8Parser.m3u8Data
            self.downloader.startDownload()
        }) { [weak self] error in
            print(error)
            showMessage(message: error.localizedDescription)
            self?.downloadStatus.accept(.failed)
        }
    }

    func getPlayPath() -> String? {
        return VideoPlayServer.getServer(name: directoryName)
    }
}

class VideoPlayServer {
    static var currentServer: GCDWebDAVServer?
    public static func getServer(name: String) -> String? {
        currentServer?.stop()
        let dirPath = getDocumentsDirectory().appendingPathComponent("Downloads").appendingPathComponent(name).path
        currentServer = GCDWebDAVServer(uploadDirectory: dirPath)
        currentServer?.start()
        let playPath = "http://127.0.0.1:8080/" + name + ".m3u8"
        return playPath
    }
}

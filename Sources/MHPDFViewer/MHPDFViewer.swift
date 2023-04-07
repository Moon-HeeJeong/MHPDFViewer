import Foundation
import UIKit

public class MHPDFViewer: NSObject{
    
    public enum LoadStatus{
        case start
        case ing
        case end(isSuccess: Bool, errorMessage: String?)
    }
    public typealias MHDownloaderStatusCloser = (LoadStatus)->()
    private var _statusCloser: MHDownloaderStatusCloser?
    
    deinit{
        print("deinit \(self)")
    }
    
    private let _documentInteractionController: UIDocumentInteractionController
    private var _task: URLSessionDataTask?
    public var canOpen: Bool = true
    
    unowned let presenter: UIViewController
    
    public init(presenter: UIViewController, closer: MHDownloaderStatusCloser? = nil) {
        self.presenter = presenter
        self._documentInteractionController = UIDocumentInteractionController()
        
        super.init()
        self._documentInteractionController.delegate = self
        self._statusCloser = closer
    }
    
    public func open(urlStr: String?, title: String){
        
        guard self.canOpen else {
            return
        }
        
        if let s = urlStr{
            if #available(iOS 10.0, *) {
                self.storeAndShare(withURLString: s, title: title)
            } else {
                UIApplication.shared.openURL(URL(string: s)!)
            }
        }else{
            print("ERROR : Downloader URL Incorrected")
        }
    }
    
    
    private func share(url: URL, title: String) {
        self._documentInteractionController.url = url
        self._documentInteractionController.uti = (try? url.resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier ?? "public.data, public.content"
        self._documentInteractionController.name = title
        self._documentInteractionController.presentPreview(animated: true)
    }
    
    /// This function will store your document to some temporary URL and then provide sharing, copying, printing, saving options to the user
    private func storeAndShare(withURLString: String, title: String) {
        self._statusCloser?(.start)
        guard let url = URL(string: withURLString) else {
            self._statusCloser?(.end(isSuccess: false, errorMessage: "ERROR : Downloader URL Incorrected"))
            return
        }
        
        self._task = URLSession.shared.dataTask(with: url) { data, response, error in
            
            self._statusCloser?(.ing)
            
            guard let data = data, error == nil else {
                DispatchQueue.main.async {
                    self._statusCloser?(.end(isSuccess: false, errorMessage: error?.localizedDescription))
                }
                return
            }
            
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent(response?.suggestedFilename ?? "")
            do {
                try data.write(to: tmpURL)
            } catch {
                print(error.localizedDescription)
                DispatchQueue.main.async {
                    self._statusCloser?(.end(isSuccess: false, errorMessage: error.localizedDescription))
                }
            }
            DispatchQueue.main.async {
                self.share(url: tmpURL, title: title)
                self._statusCloser?(.end(isSuccess: true, errorMessage: nil))
            }
        }
        self._task?.resume()
    }
    
    public func cancel(){
         self._task?.cancel()
        print("Downloader cancelled")
    }
}

extension MHPDFViewer: UIDocumentInteractionControllerDelegate {
    public func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
//        guard let presenter = self.presenter, let navVC = presenter.parent?.navigationController else {
//            return presenter!
//        }
//        return navVC
        self.presenter
    }
}


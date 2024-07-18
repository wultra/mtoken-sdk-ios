//
// Copyright 2024 Wultra s.r.o.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions
// and limitations under the License.
//

import UIKit

/// Simple image URL downloader with a simple cache implementation
internal class ImageDownloader {
    
    public static let shared = ImageDownloader()
    
    public class Callback {
        
        fileprivate let callback: (UIImage?) -> Void
        fileprivate(set) var canceled = false
        
        public init(callback: @escaping (UIImage?) -> Void) {
            self.callback = callback
        }
        
        public func cancel() {
            canceled = true
        }
        
        fileprivate func setResult(_ image: UIImage?) {
            guard canceled == false else {
                return
            }
            callback(image)
        }
    }
    
    private var cache: NSCache<NSString, UIImage>
    
    private var waitingList = [URL: [Callback]]()
    private let lock = WMTLock()
    
    public init(byteCacheSize: Int = 20_000_000) { // ~20 mb
        cache = NSCache()
        cache.totalCostLimit = byteCacheSize
    }
    
    /// Downloads image for given URL
    /// - Parameters:
    ///   - url: URL where the image is
    ///   - allowCache: If the image can be cached or loaded from cache
    ///   - delayError: Should error be delayed? For example, when the URL does not exist (404), it will fail in almost instant and it's better
    ///   for the UI to "simulate communication".
    ///   - completion: Completion with nil on error. Always invoked on main thread
    public func downloadImage(at url: URL, allowCache: Bool = true, delayError: Bool = true, _ callback: Callback) {
        
        if allowCache, let cached = cache.object(forKey: NSString(string: url.absoluteString)) {
            callback.setResult(cached)
            return
        }
        
        lock.synchronized {
            if var list = waitingList[url] {
                list.append(callback)
                waitingList[url] = list
            } else {
                waitingList[url] = [callback]
            }
        }
        
        DispatchQueue.global().async { [weak self] in
            
            let started = Date()
            let data = try? Data(contentsOf: url)
            let elapsed = Date().timeIntervalSince(started)
            let delay = delayError && data == nil && elapsed < 0.8
            
            DispatchQueue.main.asyncAfter(deadline: .now() + (delay ? 0.7 : 0) ) {
                
                guard let self else {
                    return
                }
                
                self.lock.synchronized {
                    if let data, let image = UIImage(data: data) {
                        if allowCache {
                            self.cache.setObject(image, forKey: NSString(string: url.absoluteString), cost: data.count)
                        }
                        self.waitingList[url]?.forEach { $0.setResult(image) }
                    } else {
                        self.waitingList[url]?.forEach { $0.setResult(nil) }
                    }
                    
                    self.waitingList.removeValue(forKey: url)
                }
            }
        }
    }
}

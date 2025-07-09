//
//  NotificationService.swift
//  VirtualFridgeNotificationImage
//
//  Created by Damir Kamalov on 01.07.2025.
//
/*
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {
            let imageURLString = "https://firebasestorage.googleapis.com/v0/b/virtualfridge-780f1.firebasestorage.app/o/iTunesArtwork%401x.png?alt=media&token=07cf142a-d5d3-4dd7-878e-3e0acc467559"

            if let imageURL = URL(string: imageURLString) {
                downloadImage(from: imageURL) { attachment in
                    if let attachment = attachment {
                        bestAttemptContent.attachments = [attachment]
                    }
                    contentHandler(bestAttemptContent)
                }
            } else {
                contentHandler(bestAttemptContent)
            }
        } else {
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func downloadImage(from url: URL, completion: @escaping (UNNotificationAttachment?) -> Void) {
        let task = URLSession.shared.downloadTask(with: url) { downloadURL, _, _ in
            guard let downloadURL = downloadURL else {
                completion(nil)
                return
            }

            let tempDirectory = FileManager.default.temporaryDirectory
            let tempFile = tempDirectory.appendingPathComponent(url.lastPathComponent)

            try? FileManager.default.moveItem(at: downloadURL, to: tempFile)

            let attachment = try? UNNotificationAttachment(identifier: "image", url: tempFile, options: nil)
            completion(attachment)
        }
        task.resume()
    }
}
*/

# Using Inbox Service

<!-- begin remove -->
- [Introduction](#introduction)
- [Creating an Instance](#creating-an-instance)
- [Inbox Service Usage](#inbox-service-usage)
  - [Get Number of Unread Messages](#get-number-of-unread-messages)
  - [Get List of Messages](#get-list-of-messages)
  - [Get Message Detail](#get-message-detail)
  - [Set Message as Read](#set-message-as-read)
- [Error handling](#error-handling)

## Introduction
<!-- end -->

Inbox Service is responsible for managing messages in the Inbox. The inbox is a simple one-way delivery system that allows you to deliver messages to the user.

<!-- begin box warning -->
Note: Before using Inbox Service, you need to have a `PowerAuthSDK` object available and initialized with a valid activation. Without a valid PowerAuth activation, the service will return an error.
<!-- end -->

Inbox Service communicates with the [Mobile Token API](https://developers.wultra.com/components/enrollment-server/develop/documentation/Mobile-Token-API).

## Creating an Instance

### On Top of the `PowerAuthSDK` instance
```swift
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

let networkingConfig = WPNConfig(
    baseUrl: URL(string: "https://myservice.com/mtoken/inbox/api/")!,
    sslValidation: .default
)
// powerAuth is instance of PowerAuthSDK
let inboxService = powerAuth.createWMTInbox(networkingConfig: networkingConfig)
```

### On Top of the `WPNNetworkingService` instance
```swift
import WultraMobileTokenSDK

// networkingService is instance of WPNNetworkingService
let inboxService = networkingService.createWMTInbox()
```

## Inbox Service Usage

### Get Number of Unread Messages

To get the number of unread messages, use the following code:

```swift
inboxService.getUnreadCount { result in
    switch result {
    case .success(let count):
        if count.countUnread > 0 {
            print("There are \(count.countUnread) new message(s) in your inbox")
        } else {
            print("Your inbox is empty")
        }
    case .failure(let error):
        print("Error \(error)")
    }    
}
```

### Get a List of Messages

The Inbox Service provides a paged list of messages:

```swift
// First page is 0, next 1, etc...
inboxService.getMessageList(pageNumber: 0, pageSize: 50, onlyUnread: false) { result in
    switch result {
    case .success(let messages):
        if messages.count < 50 {
            // This is the last page
        }
        // Process result
    case .faulure(let error):
        // Process error...
    } 
}
```

To get the list of all messages, call:

```swift
inboxService.getAllMessages { result in 
    switch result {
    case .success(let messages):
        print("Inbox contains the following message(s):")
        for msg in messages {
            print(" - \(msg.subject)")
            print("   * ID = \(msg.id)")
        }
    case .failure(let error):
        print("Error \(error)")
    }
}
```

### Get Message Detail

Each message has its unique identifier. To get the body of the message, use the following code:

```swift
let messageId = messagesList.first!.id
inboxService.getMessageDetail(messageId: messageId) { result in 
    switch result {
    case .success(let detail):
        print("Received message:")
        print("\(detail.subject)")
        print("\(detail.body)")
    case .failure(let error):
        print("Error \(error)")
    }
}
```

### Set Message as Read

To mark the message as read by the user, use the following code:

```swift
let messageId = messagesList.first!.id
inboxService.markRead(messageId: messageId) {
    switch result {
    case .success:
        print("OK")
    case .failure(let error):
        print("Error \(error)")
    }
}
```

Alternatively, you can mark all messages as read:

```swift
inboxService.markAllRead {
    switch result {
    case .success:
        print("OK")
    case .failure(let error):
        print("Error \(error)")
    }
}
```

## Error handling

Every error produced by the Inbox Service is of a `WMTError` type. For more information see detailed [error handling documentation](Error-Handling.md).

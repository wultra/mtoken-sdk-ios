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

The preferred way of instantiating Inbox Service is via `WultraMobileToken` class.
See: [Example Usage](./Example-Usage)


### Customized initialization

If you need to create a more customized instance, such as when your Push Service uses a different enrollment server URL than other services in the SDK, you can use an initializer. Simply define the networking configuration and provide the PowerAuthSDK instance.

```swift
import WultraMobileTokenSDK
import WultraPowerAuthNetworking

let networkingConfig = WPNConfig(
    baseUrl: URL(string: "https://powerauth.myservice.com/enrollment-server")!,
    sslValidation: .default
)

let networkingService = WPNNetworkingService(
    powerAuth: powerAuth,
    config: networkingConfig,
    serviceName: "InboxService",
    acceptLanguage: "en"
)

let opsService = WMTInbox(networking: networkingService)
```

## Inbox Service Usage

Note: All async/throws methods shown here also have callback-based counterparts (`completion: @escaping (Result<…, WMTError>) -> Void`) if you prefer the closure style.

### Get Number of Unread Messages

To get the number of unread messages, use the following code:

```swift
Task {
    do {
        let count = try await inboxService.getUnreadCount()
        if count.countUnread > 0 {
            print("There are \(count.countUnread) new message(s) in your inbox")
        } else {
            print("Your inbox is empty")
        }
    } catch {
        print("Error \(error)")
    }
}
```

### Get a List of Messages

The Inbox Service provides a paged list of messages:

```swift
Task {
    do {
        // First page is 0, next 1, etc...
        let messages = try await inboxService.getMessageList(pageNumber: 0, pageSize: 50, onlyUnread: false)
        if messages.count < 50 {
            // This is the last page
        }
        // Process result
    } catch {
        // Process error...
    }
}
```

To get the list of all messages, call:

```swift
Task {
    do {
        let messages = try await inboxService.getAllMessages()
        print("Inbox contains the following message(s):")
        for msg in messages {
            print(" - \(msg.subject)")
            print("   * ID = \(msg.id)")
        }
    } catch {
        print("Error \(error)")
    }
}
```

### Get Message Detail

Each message has its unique identifier. To get the body of the message, use the following code:

```swift
let messageId = messagesList.first!.id
Task {
    do {
        let detail = try await inboxService.getMessageDetail(messageId: messageId)
        print("Received message:")
        print("\(detail.subject)")
        print("\(detail.body)")
    } catch {
        print("Error \(error)")
    }
}
```

### Set Message as Read

To mark the message as read by the user, use the following code:

```swift
let messageId = messagesList.first!.id
Task {
    do {
        try await inboxService.markRead(messageId: messageId)
        print("OK")
    } catch {
        print("Error \(error)")
    }
}
```

Alternatively, you can mark all messages as read:

```swift
Task {
    do {
        try await inboxService.markAllRead()
        print("OK")
    } catch {
        print("Error \(error)")
    }
}
```

## Error handling

Every error produced by the Inbox Service is of a `WMTError` type. For more information see detailed [error handling documentation](Error-Handling.md).

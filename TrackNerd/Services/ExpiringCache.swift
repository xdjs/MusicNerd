import Foundation

actor ExpiringCache<Key: Hashable & Sendable, Value: Sendable> {
  struct Entry: Sendable {
    let value: Value
    let expiresAt: Date

    func isExpired(at date: Date) -> Bool {
      date >= expiresAt
    }
  }

  private var entries: [Key: Entry] = [:]

  func entry(for key: Key) -> Entry? {
    entries[key]
  }

  func insert(
    _ value: Value,
    for key: Key,
    timeToLive: TimeInterval,
    now: Date
  ) {
    entries[key] = Entry(
      value: value,
      expiresAt: now.addingTimeInterval(timeToLive)
    )
  }

  func removeValue(for key: Key) {
    entries.removeValue(forKey: key)
  }

  func removeAll() {
    entries.removeAll()
  }
}

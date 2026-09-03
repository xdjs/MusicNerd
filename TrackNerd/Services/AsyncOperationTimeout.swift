import Foundation

struct AsyncOperationTimeout: Sendable {
  enum Failure: Error, Equatable, Sendable {
    case timedOut
  }

  typealias Sleeper = @Sendable (UInt64) async throws -> Void

  private let sleep: Sleeper

  init(
    sleep: @escaping Sleeper = { nanoseconds in
      try await Task.sleep(nanoseconds: nanoseconds)
    }
  ) {
    self.sleep = sleep
  }

  func run<Value: Sendable>(
    after nanoseconds: UInt64,
    operation: @escaping @Sendable () async throws -> Value
  ) async throws -> Value {
    try Task.checkCancellation()

    return try await withThrowingTaskGroup(of: Value.self) { group in
      group.addTask {
        try await operation()
      }
      group.addTask { [sleep] in
        try await sleep(nanoseconds)
        try Task.checkCancellation()
        throw Failure.timedOut
      }

      defer { group.cancelAll() }

      guard let firstResult = try await group.next() else {
        throw Failure.timedOut
      }
      return firstResult
    }
  }
}

//
//  TaskCancelBox.swift
//  TheLightUI
//

import Foundation

/// Thread-safe holder for a single in-flight, fire-and-forget `Task`.
///
/// View models commonly need to cancel an in-progress `Task` from a
/// `nonisolated deinit`, which runs on an arbitrary thread while the task is
/// otherwise only ever replaced from `@MainActor` methods. Storing the task
/// directly in a `nonisolated(unsafe) var` suppresses Swift's data-race
/// check without actually providing one. This box does, via an `NSLock`,
/// and is a `let` constant so it's safe to touch from `deinit` on any class
/// that holds one.
final class TaskCancelBox: @unchecked Sendable {
    private let lock = NSLock()
    private var task: Task<Void, Never>?

    /// Cancels any task currently held, then stores `newTask` in its place.
    func replace(with newTask: Task<Void, Never>?) {
        lock.withLock {
            task?.cancel()
            task = newTask
        }
    }

    /// Cancels and clears the held task, if any. Safe to call from `deinit`.
    func cancel() {
        lock.withLock {
            task?.cancel()
            task = nil
        }
    }
}

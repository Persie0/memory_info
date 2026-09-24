import Darwin
import Foundation
import FlutterMacOS

public final class MemoryInfoPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: "github.com/MrOlolo/memory_info",
      binaryMessenger: registrar.messenger
    )
    let instance = MemoryInfoPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDiskSpace":
      result([
        "diskFreeSpace": diskFreeSpaceMB(),
        "diskTotalSpace": diskTotalSpaceMB(),
      ])
    case "getMemoryInfo":
      result([
        "usedByApp": memoryUsedByAppMB(),
        "total": physicalMemoryMB(),
        "free": freeMemoryMB(),
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func physicalMemoryMB() -> Double {
    Double(ProcessInfo.processInfo.physicalMemory) / 1_048_576.0
  }

  private func freeMemoryMB() -> Double {
    var statistics = vm_statistics64_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<vm_statistics64_data_t>.size /
        MemoryLayout<integer_t>.size
    )

    let status = withUnsafeMutablePointer(to: &statistics) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        host_statistics64(
          mach_host_self(),
          HOST_VM_INFO64,
          $0,
          &count
        )
      }
    }
    guard status == KERN_SUCCESS else { return 0 }

    var pageSize: vm_size_t = 0
    guard host_page_size(mach_host_self(), &pageSize) == KERN_SUCCESS else {
      return 0
    }

    // Include speculative pages: macOS can reclaim them immediately and they
    // represent usable headroom for a memory-intensive processing job.
    let availablePages =
      UInt64(statistics.free_count) + UInt64(statistics.speculative_count)
    return Double(availablePages * UInt64(pageSize)) / 1_048_576.0
  }

  private func memoryUsedByAppMB() -> Double {
    var info = task_vm_info_data_t()
    var count = mach_msg_type_number_t(
      MemoryLayout<task_vm_info_data_t>.size /
        MemoryLayout<integer_t>.size
    )
    let status = withUnsafeMutablePointer(to: &info) { pointer in
      pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
        task_info(
          mach_task_self_,
          task_flavor_t(TASK_VM_INFO),
          $0,
          &count
        )
      }
    }
    guard status == KERN_SUCCESS else { return 0 }
    return Double(info.phys_footprint) / 1_048_576.0
  }

  private func diskTotalSpaceMB() -> Int64 {
    guard
      let attributes = try? FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      ),
      let size = (attributes[.systemSize] as? NSNumber)?.int64Value
    else {
      return 0
    }
    return size / 1_048_576
  }

  private func diskFreeSpaceMB() -> Int64 {
    let homeURL = URL(fileURLWithPath: NSHomeDirectory())
    if let values = try? homeURL.resourceValues(
      forKeys: [.volumeAvailableCapacityForImportantUsageKey]
    ), let capacity = values.volumeAvailableCapacityForImportantUsage {
      return capacity / 1_048_576
    }

    guard
      let attributes = try? FileManager.default.attributesOfFileSystem(
        forPath: NSHomeDirectory()
      ),
      let size = (attributes[.systemFreeSize] as? NSNumber)?.int64Value
    else {
      return 0
    }
    return size / 1_048_576
  }
}

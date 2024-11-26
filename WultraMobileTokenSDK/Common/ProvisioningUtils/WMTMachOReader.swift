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

import Foundation
import MachO
import CommonCrypto

class WMTMachOReader {

    private struct CSSuperBlob {
        var magic: UInt32
        var length: UInt32
        var count: UInt32
    }

    private struct CSBlob {
        var type: UInt32
        var offset: UInt32
    }

    private struct CSMagic {
        static let embeddedSignature: UInt32 = 0xfade0cc0
        static let embeddedEntitlements: UInt32 = 0xfade7171
    }

    private enum BinaryType {
        struct HeaderData {
            let headerSize: Int
            let commandCount: Int
        }
        struct FatHeaderData {
            let archCount: Int
        }
        case singleArch(headerInfo: HeaderData)
        case fat(header: FatHeaderData)
    }

    private var entitlements = [WMTProvision.Entitlements]()
    
    static func readEntitlements(_ binaryPath: String) -> [WMTProvision.Entitlements]? {
        WMTMachOReader(binaryPath)?.entitlements
    }

    private init?(_ binaryPath: String) {
        guard let binary = BinaryReader(binaryPath) else {
            return nil
        }
        
        switch getBinaryType(binary: binary) {
        case .singleArch(let headerInfo):
            let headerSize = headerInfo.headerSize
            let commandCount = headerInfo.commandCount
            if let data = readEntitlementsFromBinarySlice(binary: binary, headerOffset: headerSize, dataOffset: 0, cmdCount: commandCount) {
                entitlements.append(data)
            }
        case .fat(let header):
            entitlements.append(contentsOf: readEntitlementsFromFatBinary(binary: binary, architectureCount: header.archCount, startingAt: MemoryLayout<fat_header>.size))
        default:
            return nil
        }
    }

    private func getBinaryType(binary: BinaryReader, fromSliceStartingAt offset: UInt64 = 0) -> BinaryType? {
        binary.seek(to: offset)
        let header: mach_header = binary.read()
        let commandCount = Int(header.ncmds)
        switch header.magic {
        case MH_MAGIC:
            let data = BinaryType.HeaderData(headerSize: MemoryLayout<mach_header>.size, commandCount: commandCount)
            return .singleArch(headerInfo: data)
        case MH_MAGIC_64:
            let data = BinaryType.HeaderData(headerSize: MemoryLayout<mach_header_64>.size, commandCount: commandCount)
            return .singleArch(headerInfo: data)
        default:
            binary.seek(to: 0)
            let fatHeader: fat_header = binary.read()
            if CFSwapInt32(fatHeader.magic) == FAT_MAGIC {
            let archCount = Int(CFSwapInt32(fatHeader.nfat_arch))
                return .fat(header: BinaryType.FatHeaderData(archCount: archCount))
            } else {
                return nil
            }
        }
    }
    
    private func readEntitlementsFromFatBinary(binary: BinaryReader, architectureCount: Int, startingAt: Int) -> [WMTProvision.Entitlements] {
        var entitlements = [WMTProvision.Entitlements]()
        for i in 0..<architectureCount {
            let offset = startingAt + (i * MemoryLayout<fat_arch>.size)
            binary.seek(to: UInt64(offset))
            let fatArch: fat_arch = binary.read()
            let fatArchOffset = CFSwapInt32(fatArch.offset)
            let arch = getBinaryType(binary: binary, fromSliceStartingAt: UInt64(fatArchOffset))
            switch arch {
            case .singleArch(let headerInfo):
                let headerOffset = Int(fatArchOffset) + headerInfo.headerSize
                if let parsed = readEntitlementsFromBinarySlice(binary: binary, headerOffset: headerOffset, dataOffset: fatArchOffset, cmdCount: headerInfo.commandCount) {
                    entitlements.append(parsed)
                }
            default:
                break
            }
        }
        return entitlements
    }

    private func readEntitlementsFromBinarySlice(binary: BinaryReader, headerOffset: Int, dataOffset: UInt32, cmdCount: Int) -> WMTProvision.Entitlements? {
        binary.seek(to: UInt64(headerOffset))
        for _ in 0..<cmdCount {
            let command: load_command = binary.read()
            if command.cmd == LC_CODE_SIGNATURE {
                let signatureOffset: UInt32 = binary.read()
                return readEntitlementsData(binary: binary, startingAt: signatureOffset + dataOffset)
            }
            binary.seek(to: binary.currentOffset + UInt64(command.cmdsize - UInt32(MemoryLayout<load_command>.size)))
        }
        return nil
    }

    private func readEntitlementsData(binary: BinaryReader, startingAt offset: UInt32) -> WMTProvision.Entitlements? {
        binary.seek(to: UInt64(offset))
        let metaBlob: CSSuperBlob = binary.read()
        if CFSwapInt32(metaBlob.magic) == CSMagic.embeddedSignature {
            let metaBlobSize = UInt32(MemoryLayout<CSSuperBlob>.size)
            let blobSize = UInt32(MemoryLayout<CSBlob>.size)
            let itemCount = CFSwapInt32(metaBlob.count)
            for index in 0..<itemCount {
                let readOffset = UInt64(offset + metaBlobSize + index * blobSize)
                binary.seek(to: readOffset)
                let blob: CSBlob = binary.read()
                binary.seek(to: UInt64(offset + CFSwapInt32(blob.offset)))
                let blobMagic = CFSwapInt32(binary.read())
                if blobMagic == CSMagic.embeddedEntitlements {
                    let signatureLength = CFSwapInt32(binary.read())
                    let signatureData = binary.readData(ofLength: Int(signatureLength) - 8)
                    return try? PropertyListDecoder().decode(WMTProvision.Entitlements.self, from: signatureData)
                }
            }
        }
        return nil
    }
}

private class BinaryReader {

    private let handle: FileHandle

    init?(_ path: String) {
        guard let binaryHandle = FileHandle(forReadingAtPath: path) else {
            return nil
        }
        handle = binaryHandle
    }

    var currentOffset: UInt64 { handle.offsetInFile }

    func seek(to offset: UInt64) {
        handle.seek(toFileOffset: offset)
    }

    func read<T>() -> T {
        handle.readData(ofLength: MemoryLayout<T>.size).withUnsafeBytes({ $0.load(as: T.self) })
    }

    func readData(ofLength length: Int) -> Data {
        handle.readData(ofLength: length)
    }

    deinit {
        handle.closeFile()
    }
}

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

internal struct MachOSignatureBlob {
    let pkcs: PKCS7?
    let entitlemens: Entitlements?
}

internal class MachOReader {

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
        static let blobWrapper: UInt32 = 0xfade0b01
        static let codeDirectory: UInt32 = 0xfade0c02
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

    private var blobs: [MachOSignatureBlob]!
    
    static func readSignatures(_ binaryPath: String) -> [MachOSignatureBlob]? {
        MachOReader(binaryPath)?.blobs
    }

    private init?(_ binaryPath: String) {
        guard let binary = BinaryReader(binaryPath) else {
            return nil
        }
        
        switch getBinaryType(binary: binary) {
        case .singleArch(let headerInfo):
            let headerSize = headerInfo.headerSize
            let commandCount = headerInfo.commandCount
            blobs = [readSignatureFromBinarySlice(binary: binary, headerOffset: headerSize, dataOffset: 0, cmdCount: commandCount)]
        case .fat(let header):
            blobs = readSignaturesFromFatBinary(binary: binary, architectureCount: header.archCount, startingAt: MemoryLayout<fat_header>.size)
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
    
    private func readSignaturesFromFatBinary(binary: BinaryReader, architectureCount: Int, startingAt: Int) -> [MachOSignatureBlob] {
        var blobs = [MachOSignatureBlob]()
        for i in 0..<architectureCount {
            let offset = startingAt + (i * MemoryLayout<fat_arch>.size)
            binary.seek(to: UInt64(offset))
            let fatArch: fat_arch = binary.read()
            let fatArchOffset = CFSwapInt32(fatArch.offset)
            let arch = getBinaryType(binary: binary, fromSliceStartingAt: UInt64(fatArchOffset))
            switch arch {
            case .singleArch(let headerInfo):
                let headerOffset = Int(fatArchOffset) + headerInfo.headerSize
                blobs.append(readSignatureFromBinarySlice(binary: binary, headerOffset: headerOffset, dataOffset: fatArchOffset, cmdCount: headerInfo.commandCount))
            default:
                blobs.append(MachOSignatureBlob(pkcs: nil, entitlemens: nil))
            }
        }
        return blobs
    }

    private func readSignatureFromBinarySlice(binary: BinaryReader, headerOffset: Int, dataOffset: UInt32, cmdCount: Int) -> MachOSignatureBlob {
        binary.seek(to: UInt64(headerOffset))
        var blob: MachOSignatureBlob?
        for _ in 0..<cmdCount {
            let command: load_command = binary.read()
            if command.cmd == LC_CODE_SIGNATURE {
                let signatureOffset: UInt32 = binary.read()
                blob = readSignatureData(binary: binary, startingAt: signatureOffset + dataOffset)
                break
            }
            binary.seek(to: binary.currentOffset + UInt64(command.cmdsize - UInt32(MemoryLayout<load_command>.size)))
        }
        return blob ?? MachOSignatureBlob(pkcs: nil, entitlemens: nil)
    }

    private func readSignatureData(binary: BinaryReader, startingAt offset: UInt32) -> MachOSignatureBlob {
        var pkcs: PKCS7?
        var entitlements: Entitlements?
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
                    entitlements = Entitlements(signatureData)
                } else if blobMagic == CSMagic.blobWrapper {
                    let blobLength = CFSwapInt32(binary.read())
                    let blobData: Data = binary.readData(ofLength: Int(blobLength) - 8)
                    pkcs = try? PKCS7(data: blobData)
                }
            }
            
        }
        return MachOSignatureBlob(pkcs: pkcs, entitlemens: entitlements)
    }
}

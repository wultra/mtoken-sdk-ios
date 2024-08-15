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

/// This is a utility class responsible for preparing visual representations of `WMTUserOperation`.
///
/// It generates visual data for both list and detailed views of the operations from `WMTOperationFormData` and its `WMTOperationAttribute`.
/// The visual data are created based on the sctructure of the `WMTTemplates`.
public class WMTTemplateVisualParser {
    
    /// Prepares the visual representation for the given `WMTUserOperation` in a list view.
    /// - Parameter operation: The user operation to prepare the visual data for.
    /// - Returns: A `WMTTemplateListVisual` instance containing the visual data.
    public static func prepareForList(operation: WMTUserOperation) -> WMTTemplateListVisual {
        return operation.prepareVisualListDetail()
    }
    
    /// Prepares the visual representation for a detail view of the given user operation.
    /// - Parameter operation: The user operation to prepare the visual data for.
    /// - Returns: A `WMTTemplateDetailVisual` instance containing the visual data.
    public static func prepareForDetail(operation: WMTUserOperation) -> WMTTemplateDetailVisual {
        return operation.prepareVisualDetail()
    }
}

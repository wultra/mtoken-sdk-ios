//
// Copyright 2020 Wultra s.r.o.
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

public class WMTOperationAttributeAmount: WMTOperationAttribute {

    /// amount might not be precise (due to floating point conversion during deserialization from json)
    /// use amountFormatted property instead when available
    public let amount: Decimal
    public let currency: String
    // optional variables for backend compatibility (this feature was introduced in 2018.12)
    public let amountFormatted: String?
    public let currencyFormatted: String?
    
    private enum Keys: CodingKey {
        case amount, amountFormatted, currency, currencyFormatted
    }
    
    public init(label: WMTOperationParameter, amount: Decimal, currency: String, amountFormatted: String?, currencyFormatted: String?) {
        self.amount = amount
        self.currency = currency
        self.amountFormatted = amountFormatted
        self.currencyFormatted = currencyFormatted
        super.init(type: .amount, label: label)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        
        amount = (try c.decode(Double.self, forKey: .amount) as NSNumber).decimalValue
        amountFormatted = try? c.decode(String.self, forKey: .amountFormatted)
        currencyFormatted = try? c.decode(String.self, forKey: .currencyFormatted)
        currency = try c.decode(String.self, forKey: .currency)
        
        try super.init(from: decoder)
    }
}

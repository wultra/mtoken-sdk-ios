//
// Copyright 2023 Wultra s.r.o.
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

/// Conversion attribute is 1 row in operation, that represents "Money Conversion"
public class WMTOperationAttributeAmountConversion: WMTOperationAttribute {
    
    public struct Money {
        
        /// Payment amount
        ///
        /// Amount might not be precise (due to floating point conversion during deserialization from json)
        /// use amountFormatted property instead when available
        public let amount: Decimal
        
        /// Currency
        public let currency: String
        
        /// Formatted amount for presentation.
        ///
        /// This property will be properly formatted based on the response language.
        /// For example when amount is 100 and the acceptLanguage is "cs" for czech,
        /// the amountFormatted will be "100,00".
        public let amountFormatted: String?
        
        /// Formatted currency to the locale based on acceptLanguage
        ///
        /// For example when the currency is CZK, this property will be "Kč"
        public let currencyFormatted: String?
    }
    
    /// If the conversion is dynamic and the application should refresh it periodically
    ///
    /// This is just a hint for the application UI. This SDK does not offer feature to periodically
    /// refresh conversion rate.
    public let dynamic: Bool
    
    /// Source amount
    public let source: Money
    
    /// Target amount
    public let target: Money
    
    public init(label: AttributeLabel, dynamic: Bool, source: Money, target: Money) {
        self.dynamic = dynamic
        self.source = source
        self.target = target
        super.init(type: .amountConversion, label: label)
    }
    
    // MARK: - INTERNALS
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        
        self.dynamic = try c.decode(Bool.self, forKey: .dynamic)
        self.source = .init(
            amount: try c.decode(Decimal.self, forKey: .sourceAmount),
            currency: try c.decode(String.self, forKey: .sourceCurrency),
            amountFormatted: try? c.decode(String.self, forKey: .sourceAmountFormatted),
            currencyFormatted: try? c.decode(String.self, forKey: .sourceCurrencyFormatted)
        )
        self.target = .init(
            amount: try c.decode(Decimal.self, forKey: .targetAmount),
            currency: try c.decode(String.self, forKey: .targetCurrency),
            amountFormatted: try? c.decode(String.self, forKey: .targetAmountFormatted),
            currencyFormatted: try? c.decode(String.self, forKey: .targetCurrencyFormatted)
        )
        
        try super.init(from: decoder)
    }
    
    private enum Keys: CodingKey {
        case dynamic, sourceAmount, sourceCurrency, sourceAmountFormatted, sourceCurrencyFormatted,
             targetAmount, targetCurrency, targetAmountFormatted, targetCurrencyFormatted
    }
}

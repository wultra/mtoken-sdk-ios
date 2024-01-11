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
        
        /// Formatted amount for presentation.
        ///
        /// This property will be properly formatted based on the response language.
        /// For example when amount is 100 and the acceptLanguage is "cs" for czech,
        /// the amountFormatted will be "100,00".
        public let amountFormatted: String
        
        /// Formatted currency to the locale based on acceptLanguage
        ///
        /// For example when the currency is CZK, this property will be "Kč"
        public let currencyFormatted: String

        /// Payment amount
        ///
        /// Amount might not be precise (due to floating point conversion during deserialization from json)
        /// use amountFormatted property instead when available
        public let amount: Decimal?
        
        /// Currency
        public let currency: String?

        /// Formatted currency and amount to the locale based on acceptLanguage
        ///
        /// Both amount and currency are formatted, String will show e.g. "€" in front of the amount
        /// or "EUR" behind the amount depending on locale
        public let valueFormatted: String?
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
        // For backward compatibility with legacy implementation, where the `sourceAmountFormatted` and `sourceCurrencyFormatted` values might not be present,
        // we directly decode from `sourceAmount` and `sourceCurrency`.
        self.source = .init(
            amountFormatted: try c.decodeIfPresent(String.self, forKey: .sourceAmountFormatted) ?? String(c.decode(Double.self, forKey: .sourceAmount)),
            currencyFormatted: try c.decodeIfPresent(String.self, forKey: .sourceCurrencyFormatted) ?? c.decode(String.self, forKey: .sourceCurrency),
            amount: try? c.decode(Decimal.self, forKey: .sourceAmount),
            currency: try? c.decode(String.self, forKey: .sourceCurrency),
            valueFormatted: try? c.decode(String.self, forKey: .sourceValueFormatted)
        )
        // For backward compatibility with legacy implementation, where the `targetAmountFormatted` and `targetCurrencyFormatted` values might not be present,
        // we directly decode from `targetAmount` and `targetCurrency`.
        self.target = .init(
            amountFormatted: try c.decodeIfPresent(String.self, forKey: .targetAmountFormatted) ?? String(c.decode(Double.self, forKey: .targetAmount)),
            currencyFormatted: try c.decodeIfPresent(String.self, forKey: .targetCurrencyFormatted) ?? c.decode(String.self, forKey: .targetCurrency),
            amount: try? c.decode(Decimal.self, forKey: .targetAmount),
            currency: try? c.decode(String.self, forKey: .targetCurrency),
            valueFormatted: try? c.decode(String.self, forKey: .targetValueFormatted)
        )
        
        try super.init(from: decoder)
    }
    
    private enum Keys: CodingKey {
        case dynamic, sourceAmount, sourceCurrency, sourceAmountFormatted, sourceCurrencyFormatted, sourceValueFormatted,
             targetAmount, targetCurrency, targetAmountFormatted, targetCurrencyFormatted, targetValueFormatted
    }
}

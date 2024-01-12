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

/// Amount attribute is 1 row in operation, that represents "Payment Amount"
public class WMTOperationAttributeAmount: WMTOperationAttribute {

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

    /// Formatted value and currency to the locale based on acceptLanguage
    ///
    /// Both amount and currency are formatted, String will show e.g. "€" in front of the amount
    /// or "EUR" behind the amount depending on the locale
    public let valueFormatted: String?
    
    // MARK: - INTERNALS
    
    private enum Keys: CodingKey {
        case amount, amountFormatted, currency, currencyFormatted, valueFormatted
    }
    
    public init(label: AttributeLabel, amountFormatted: String, currencyFormatted: String, valueFormatted: String?, amount: Decimal?, currency: String? ) {
        self.amountFormatted = amountFormatted
        self.currencyFormatted = currencyFormatted
        self.valueFormatted = valueFormatted
        self.amount = amount
        self.currency = currency
        super.init(type: .amount, label: label)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        
        // For backward compatibility with legacy implementation, where the `amountFormatted` and `currencyFormatted` values might not be present,
        // we directly decode from `amount` and `currency`.
        amountFormatted = try c.decodeIfPresent(String.self, forKey: .amountFormatted) ?? c.decode(Decimal.self, forKey: .amount).description
        currencyFormatted = try c.decodeIfPresent(String.self, forKey: .currencyFormatted) ?? c.decode(String.self, forKey: .currency)
        valueFormatted = try c.decodeIfPresent(String.self, forKey: .valueFormatted)
        amount = try c.decodeIfPresent(Decimal.self, forKey: .amount)
        currency = try c.decodeIfPresent(String.self, forKey: .currency)
        try super.init(from: decoder)
    }
}

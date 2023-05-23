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

    /// Formatted value and currency to the locale based on acceptLanguage
    ///
    /// Both amount and currency are formatted, String will show e.g. "€" in front of the amount
    /// or "EUR" behind the amount depending on the locale
    public let valueFormatted: String?
    
    // MARK: - INTERNALS
    
    private enum Keys: CodingKey {
        case amount, amountFormatted, currency, currencyFormatted, valueFormatted
    }
    
    public init(label: AttributeLabel, amount: Decimal, currency: String, amountFormatted: String?, currencyFormatted: String?, valueFormatted: String?) {
        self.amount = amount
        self.currency = currency
        self.amountFormatted = amountFormatted
        self.currencyFormatted = currencyFormatted
        self.valueFormatted = valueFormatted
        super.init(type: .amount, label: label)
    }
    
    public required init(from decoder: Decoder) throws {
        
        let c = try decoder.container(keyedBy: Keys.self)
        
        amount = (try c.decode(Double.self, forKey: .amount) as NSNumber).decimalValue
        currency = try c.decode(String.self, forKey: .currency)
        amountFormatted = try? c.decode(String.self, forKey: .amountFormatted)
        currencyFormatted = try? c.decode(String.self, forKey: .currencyFormatted)
        valueFormatted = try? c.decode(String.self, forKey: .valueFormatted)
        try super.init(from: decoder)
    }
}

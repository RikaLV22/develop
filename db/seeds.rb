banks = [
    {name: "みずほ銀行", code: "0001"},
    {name: "三菱UFJ銀行", code: "0005"},
    {name: "三井住友銀行", code: "0009"},
    {name: "りそな銀行", code: "0010"},
    {name: "埼玉りそな銀行", code: "0017"},
    {name: "PayPay銀行", code: "0033"},
    {name: "セブン銀行", code: "0034"},
    {name: "ソニー銀行", code: "0035"},
    {name: "楽天銀行", code: "0036"},
    {name: "住信SBIネット銀行", code: "0038"},
    {name: "イオン銀行", code: "0040"},
    {name: "あおぞら銀行", code: "0398"},
    {name: "ゆうちょ銀行", code: "9900"}
]

banks.each do |bank|
    Bank.find_or_create_by!(code: bank[:code], name: bank[:name])
end

Sony_bank = Bank.find_by(code:"0035")

Account.find_or_create_by!(account_number: "1234567", bank: Sony_bank, balance: 100_000)

class ChatController < ApplicationController
    def create
        message = params[:message]

        # 支出合計
        total_expense = logged_in_user.transactions
            .where(transaction_type: "expense")
            .sum(:amount)

        # 収入合計
        total_income = logged_in_user.transactions
            .where(transaction_type: "income")
            .sum(:amount)

        # カテゴリー別支出
        category_expense = logged_in_user.transactions
            .where(transaction_type: "expense")
            .group(:category)
            .sum(:amount)

        expense = logged_in_user.transactions
            .where(transaction_type: "expense")
            .sum(:amount)

        income = logged_in_user.transactions
            .where(transaction_type: "income")
            .sum(:amount)

        api_key = Rails.application.credentials.dig(:gemini, :api_key)

        conn = Faraday.new(url: "https://generativelanguage.googleapis.com")

        response = conn.post("/v1beta/models/gemini-flash-latest:generateContent?key=#{api_key}") do |req|
            req.headers["Content-Type"] = "application/json"
            req.body = {
                contents: [
                    {
                        parts: [
                           {
                            text: <<~TEXT
                                あなたは家計簿アシスタントです。

                                ユーザーの家計簿情報:
                                総収入: #{income}円
                                総支出: #{expense}円
                                残金: #{income - expense}円

                                【カテゴリー別支出】
                                #{category_expense.map{|k,v| "#{k}: #{v}円"}.join("\n")}

                                ユーザーの質問:
                                #{message}

                                家計簿情報を参考に回答してください。
                                TEXT
                            }
                        ]
                    }
                ]
            }.to_json
        end

        puts "Status: #{response.status}"
        puts "Body:"
        puts response.body

        body = JSON.parse(response.body)

        reply = body.dig(
            "candidates",
            0,
            "content",
            "parts",
            0,
            "text"
        )

        render json: {reply: reply}
    end
end

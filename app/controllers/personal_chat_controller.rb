class PersonalChatController < ApplicationController
  before_action :logged_in_user

  def create
    message = params[:message].to_s.strip

    if message.blank?
      render json: {
        error: "メッセージを入力してください"
      }, status: :unprocessable_entity
      return
    end

    user = logged_in_user

    # 個人家計簿の取引だけを取得
    transactions = user.transactions.where(
      transaction_scope: "personal"
    )

    today = Date.current

    if message.match?(/今月|今月分/)
      transactions = transactions.where(
        date: today.beginning_of_month..today.end_of_month
      )
      period_name = "今月"
    elsif message.match?(/先月|先月分/)
      last_month = today.prev_month

      transactions = transactions.where(
        date: last_month.beginning_of_month..last_month.end_of_month
      )

      period_name = "先月"
    elsif message.match?(/今年|今年分/)
      transactions = transactions.where(
        date: today.beginning_of_year..today.end_of_year
      )

      period_name = "今年"
    elsif message.match?(/去年|昨年/)
      last_year = today.prev_year

      transactions = transactions.where(
        date: last_year.beginning_of_year..last_year.end_of_year
      )

      period_name = "去年"
    else
      period_name = "全期間"
    end

    # 収入
    total_income =
      transactions
        .where(transaction_type: "income")
        .sum(:amount)

    # 支出
    total_expense =
      transactions
        .where(transaction_type: "expense")
        .sum(:amount)

    # カテゴリ別支出
    category_expense =
      transactions
        .where(transaction_type: "expense")
        .group(:category)
        .sum(:amount)

    # 収支
    balance =
      total_income - total_expense

    api_key =
      Rails.application.credentials.dig(
        :gemini,
        :api_key
      )

    if api_key.blank?
      render json: {
        error: "Gemini APIキーが設定されていません"
      }, status: :internal_server_error
      return
    end

    category_text =
      if category_expense.present?
        category_expense.map do |category, amount|
          "#{category}: #{amount}円"
        end.join("\n")
      else
        "支出データはありません"
      end

    prompt = <<~TEXT
      あなたは個人家計簿アシスタントです。

      今回の分析対象期間: #{period_name}

      以下の数字は、現在ログインしているユーザー自身の
      個人家計簿に登録された取引のうち、
      #{period_name}に該当するものだけを集計したものです。

      【#{period_name}の家計状況】
      総収入: #{total_income}円
      総支出: #{total_expense}円
      残金: #{balance}円

      【#{period_name}のカテゴリー別支出】
      #{category_text}

      【ユーザーの質問】
      #{message}

      個人家計簿情報を正確に参照して、
      ユーザーの質問に分かりやすく回答してください。

      数値を回答するときは、
      必ず上記の家計簿情報を使用してください。

      勝手に数字を推測したり、
      変更したりしないでください。

      「今月」「先月」「今年」など
      期間が指定されている場合は、
      必ず指定された期間のデータだけを使用してください。

      収支を計算する場合は、
      総収入 - 総支出
      で計算してください。

      カテゴリー別支出の合計が
      総支出と一致するか確認したうえで回答してください。
    TEXT

    models = [
      "gemini-3.6-flash",
      "gemini-3.5-flash-lite"
    ]

    conn = Faraday.new(
      url: "https://generativelanguage.googleapis.com"
    )

    reply = nil
    last_status = nil

    models.each_with_index do |model, index|
      puts "Trying Gemini model: #{model}"

      begin
        response = conn.post(
          "/v1beta/models/#{model}:generateContent?key=#{api_key}"
        ) do |req|
          req.options.timeout = 10
          req.options.open_timeout = 5

          req.headers["Content-Type"] =
            "application/json"

          req.body = {
            contents: [
              {
                parts: [
                  {
                    text: prompt
                  }
                ]
              }
            ]
          }.to_json
        end

        last_status = response.status

        puts "Model: #{model}"
        puts "Status: #{response.status}"

        if response.success?
          body = JSON.parse(response.body)

          reply =
            body.dig(
              "candidates",
              0,
              "content",
              "parts",
              0,
              "text"
            )

          break if reply.present?
        end

        if response.status >= 500 &&
           index < models.length - 1

          puts(
            "Model #{model} failed with status " \
            "#{response.status}. " \
            "Switching to #{models[index + 1]}."
          )

          next
        end

        break
      rescue Faraday::TimeoutError => e
        puts(
          "Model #{model} timed out: #{e.message}"
        )

        if index < models.length - 1
          puts(
            "Switching to #{models[index + 1]}."
          )

          next
        end

        last_status = 504
      rescue Faraday::ConnectionFailed => e
        puts(
          "Model #{model} connection failed: " \
          "#{e.message}"
        )

        if index < models.length - 1
          puts(
            "Switching to #{models[index + 1]}."
          )

          next
        end

        last_status = 502
      rescue JSON::ParserError => e
        puts(
          "JSON Parser Error: #{e.message}"
        )

        if index < models.length - 1
          puts(
            "Switching to #{models[index + 1]}."
          )

          next
        end
      end
    end

    if reply.blank?
      case last_status
      when 503
        render json: {
          error:
            "現在AIサービスが混雑しています。 " \
            "しばらくしてから再度お試しください。"
        }, status: :bad_gateway
      when 504
        render json: {
          error:
            "AIの応答に時間がかかりすぎています。 " \
            "もう一度お試しください。"
        }, status: :gateway_timeout
      else
        render json: {
          error: "AIから回答を取得できませんでした"
        }, status: :bad_gateway
      end

      return
    end

    render json: {
      reply: reply
    }
  rescue StandardError => e
    puts "Personal Chat Error: #{e.message}"
    puts e.backtrace.first(10)

    render json: {
      error: "BOTでエラーが発生しました"
    }, status: :internal_server_error
  end
end
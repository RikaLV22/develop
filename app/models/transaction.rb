class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  belongs_to :account, optional: true

  after_create :apply_balance_on_create
  after_update :apply_balance_on_update
  before_destroy :restore_balance_on_destroy

  after_create_commit :broadcast_created
  after_update_commit :broadcast_updated
  after_destroy_commit :broadcast_deleted

  validates :transaction_type, presence: true
  validates :category, presence: true
  validates :amount, presence: true
  validates :date, presence: true

  validates :transaction_scope, presence: true
  validates :transaction_scope, inclusion: {
    in: %w[organization personal]
  }

  private

  # =========================================================
  # 新規登録
  # =========================================================

  def apply_balance_on_create
    return unless account

    if transaction_type == "income"
      account.increment!(:balance, amount)
    elsif transaction_type == "expense"
      account.decrement!(:balance, amount)
    end
  end

  # =========================================================
  # 編集
  # =========================================================

  def apply_balance_on_update
    return unless balance_related_change?

    restore_previous_balance
    apply_current_balance
  end

  def balance_related_change?
    saved_change_to_account_id? ||
      saved_change_to_transaction_type? ||
      saved_change_to_amount?
  end

  def restore_previous_balance
    previous_account_id =
      account_id_before_last_save

    previous_amount =
      amount_before_last_save

    previous_transaction_type =
      transaction_type_before_last_save

    return unless previous_account_id
    return unless previous_amount

    previous_account =
      Account.find_by(id: previous_account_id)

    return unless previous_account

    if previous_transaction_type == "income"
      previous_account.decrement!(
        :balance,
        previous_amount
      )
    elsif previous_transaction_type == "expense"
      previous_account.increment!(
        :balance,
        previous_amount
      )
    end
  end

  def apply_current_balance
    return unless account

    if transaction_type == "income"
      account.increment!(
        :balance,
        amount
      )
    elsif transaction_type == "expense"
      account.decrement!(
        :balance,
        amount
      )
    end
  end

  # =========================================================
  # 削除
  # =========================================================

  def restore_balance_on_destroy
    return unless account

    if transaction_type == "income"
      account.decrement!(
        :balance,
        amount
      )
    elsif transaction_type == "expense"
      account.increment!(
        :balance,
        amount
      )
    end
  end

  # =========================================================
  # Action Cable 共通処理
  # =========================================================

  def broadcast_created
    broadcast_transaction("transaction_created")
  end

  def broadcast_updated
    broadcast_transaction("transaction_updated")
  end

  def broadcast_deleted
    payload = {
      type: "transaction_deleted",
      transaction_id: id
    }

    if transaction_scope == "organization"
      return unless organization_id

      ActionCable.server.broadcast(
        "organization_transactions_#{organization_id}",
        payload
      )
    elsif transaction_scope == "personal"
      ActionCable.server.broadcast(
        "personal_transactions_#{user_id}",
        payload
      )
    end
  end

  def broadcast_transaction(type)
    payload = {
      type: type,
      transaction: {
        id: id,
        transaction_type: transaction_type,
        amount: amount,
        date: date.to_s,
        category: category,
        payment_method: payment_method,
        account_id: account_id,
        user_id: user_id,
        user_name: user&.username,
        created_at: created_at.iso8601
      }
    }

    if transaction_scope == "organization"
      return unless organization_id

      ActionCable.server.broadcast(
        "organization_transactions_#{organization_id}",
        payload
      )
    elsif transaction_scope == "personal"
      ActionCable.server.broadcast(
        "personal_transactions_#{user_id}",
        payload
      )
    end
  end
end
class Account::ContactsExportJob < ApplicationJob
  queue_as :low

<<<<<<< HEAD
  def perform(account_id, column_names)
    account = Account.find(account_id)
    headers = valid_headers(column_names)
    return if headers.empty?

    generate_csv(account, headers)
    file_url = account_contact_export_url(account)
=======
  def perform(account_id, user_id, column_names, params)
    @account = Account.find(account_id)
    @params = params
    @account_user = @account.users.find(user_id)
>>>>>>> 499218cecfdd39a077cd3ddeeae1800d2d0e7cf5

    headers = valid_headers(column_names)
    generate_csv(headers)
    send_mail
  end

  private

  def generate_csv(headers)
    csv_data = CSV.generate do |csv|
      csv << headers
      contacts.each do |contact|
        csv << headers.map { |header| contact.send(header) }
      end
    end

    attach_export_file(csv_data)
  end

  def contacts
    if @params.present? && @params[:payload].present? && @params[:payload].any?
      result = ::Contacts::FilterService.new(@account, @account_user, @params).perform
      result[:contacts]
    elsif @params[:label].present?
      @account.contacts.resolved_contacts.tagged_with(@params[:label], any: true)
    else
      @account.contacts.resolved_contacts
    end
  end

  def valid_headers(column_names)
    (column_names.presence || default_columns) & Contact.column_names
  end

  def attach_export_file(csv_data)
    return if csv_data.blank?

    @account.contacts_export.attach(
      io: StringIO.new(csv_data),
      filename: "#{@account.name}_#{@account.id}_contacts.csv",
      content_type: 'text/csv'
    )
  end

<<<<<<< HEAD
  def account_contact_export_url(account)
    return unless account.contacts_export.attached?

    Rails.application.routes.url_helpers.rails_blob_url(account.contacts_export)
=======
  def send_mail
    file_url = account_contact_export_url
    mailer = AdministratorNotifications::ChannelNotificationsMailer.with(account: @account)
    mailer.contact_export_complete(file_url, @account_user.email)&.deliver_later
  end

  def account_contact_export_url
    Rails.application.routes.url_helpers.rails_blob_url(@account.contacts_export)
>>>>>>> 499218cecfdd39a077cd3ddeeae1800d2d0e7cf5
  end

  def default_columns
    %w[id name email phone_number]
  end
end

class EmailsController < ApplicationController
  def index
    @emails = Email.all.order(created_at: :desc)
  end

  def show
    @email = Email.find(params[:id])
    @email.update!(reader: true)
    respond_to do |format|
      format.turbo_stream
      format.html {render partial: "emails/show", locals: { email: @email }}
    end
  end
end

class ReportsController < ApplicationController
 def create
  @report = Report.new(report_params)
  @report.user = current_user

  if @report.save
    render json: { status: "success" }
  else
    logger.debug @report.errors.full_messages
    render json: { status: "error", errors: @report.errors.full_messages }, status: :unprocessable_entity
  end
end


private

def report_params
  params.require(:report).permit(:content, :reason, :post_id)
end


end

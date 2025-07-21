class FeedbacksController < ApplicationController
  before_action :authenticate_user!, only: [:new, :create]

  def new
    @feedback = Feedback.new
  end

  def create
    @feedback = current_user.feedbacks.build(feedback_params)
    if @feedback.save
      redirect_to root_path, notice: "피드백이 성공적으로 제출되었습니다. 감사합니다!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # (관리자용) 피드백 목록 보기
  def index
    @feedbacks = Feedback.order(created_at: :desc)
  end

  private

  def feedback_params
    params.require(:feedback).permit(:title, :content)
  end
end

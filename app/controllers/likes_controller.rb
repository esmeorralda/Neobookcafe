class LikesController < ApplicationController
  include ActionView::RecordIdentifier  # dom_id 헬퍼 사용 위해 추가

  before_action :authenticate_user!

  def create
    likeable = find_likeable
    if likeable && !likeable.likes.exists?(user: current_user)
      like = likeable.likes.create(user: current_user)
      likeable.increment!(:like_count) if likeable.is_a?(Post)

      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            dom_id(likeable, :like_button),
            partial: 'posts/comment_like',  # partial 경로 확인!
            locals: { likeable: likeable }
          )
        end
        format.html { redirect_back fallback_location: root_path, notice: "좋아요가 등록되었습니다." }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: root_path, alert: "이미 좋아요를 눌렀거나 대상이 없습니다." }
      end
    end
  end

def destroy
  like = current_user.likes.find_by(id: params[:id])
  unless like
    redirect_back fallback_location: root_path, alert: "좋아요가 존재하지 않습니다." and return
  end

  likeable = like.likeable

  if likeable.is_a?(Post)
    likeable.decrement!(:like_count)
  end

  like.destroy

  respond_to do |format|
    format.turbo_stream do
      render turbo_stream: turbo_stream.replace(
        dom_id(likeable, :like_button),
        partial: 'posts/comment_like',  # partial 경로 확인!
        locals: { likeable: likeable }
      )
    end
    format.html { redirect_back fallback_location: root_path, notice: "좋아요가 취소되었습니다." }
  end
end


  private

  def find_likeable
    klass = params[:likeable_type].constantize rescue nil
    klass&.find_by(id: params[:likeable_id])
  end
end

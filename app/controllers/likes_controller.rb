class LikesController < ApplicationController
    before_action :authenticate_user!
  
    def create
      likeable = find_likeable
      if likeable && !likeable.likes.exists?(user: current_user)
        like = likeable.likes.create(user: current_user)
         if likeable.is_a?(Post)
    likeable.increment!(:like_count)
  end
        flash[:notice] = "좋아요가 등록되었습니다."
      else
        flash[:alert] = "이미 좋아요를 눌렀거나 대상이 없습니다."
      end
      redirect_back fallback_location: root_path
    end

def destroy
  like = Like.find_by(id: params[:id], user: current_user)

  if like && like.likeable_type == params[:likeable_type] && like.likeable_id.to_s == params[:likeable_id].to_s
    likeable = like.likeable  # 여기서 likeable 변수 선언

    like.destroy

    if likeable.is_a?(Post) && likeable.like_count.to_i > 0
      likeable.decrement!(:like_count)
    end

    flash[:notice] = "좋아요가 취소되었습니다."
  else
    flash[:alert] = "좋아요가 없거나 권한이 없습니다."
  end

  redirect_back fallback_location: root_path
end

      
    private
  
    def find_likeable
      params[:likeable_type].constantize.find_by(id: params[:likeable_id])
    rescue NameError
      nil
    end
  end
  
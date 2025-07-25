class CommentsController < ApplicationController
    before_action :authenticate_user!
  
    # def create
    #   @comment = Comment.new(comment_params)
    #   @comment.user = current_user
    #   if @comment.save
    #     redirect_to post_path(@comment.post), notice: "댓글이 작성되었습니다."
    #   else
    #     redirect_to post_path(@comment.post), alert: "댓글 작성에 실패했습니다."
    #   end
    # end

def create
  @comment = Comment.new(comment_params)
  @comment.user = current_user

  respond_to do |format|
    if @comment.save
      format.html do
        flash[:notice] = "댓글이 등록되었습니다."
        redirect_back fallback_location: root_path
      end
      format.json { render json: { message: "댓글이 등록되었습니다." }, status: :created }
    else
      format.html do
        flash[:alert] = "댓글 등록에 실패했습니다."
        redirect_back fallback_location: root_path
      end
      format.json { render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity }
    end
  end
end

    
    
    private
  
    def comment_params
      params.require(:comment).permit(:content, :post_id, :post_block_id, :parent_id)
    end    
  end
  
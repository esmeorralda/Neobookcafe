class CommentsController < ApplicationController
    before_action :authenticate_user!
  
    def create
      @comment = Comment.new(comment_params)
      @comment.user = current_user
      if @comment.save
        redirect_to post_path(@comment.post), notice: "댓글이 작성되었습니다."
      else
        redirect_to post_path(@comment.post), alert: "댓글 작성에 실패했습니다."
      end
    end
  
    private
  
    def comment_params
      params.require(:comment).permit(:content, :post_id, :parent_id)
    end
  end
  
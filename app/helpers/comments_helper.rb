module CommentsHelper

    def reply_count_for(comment)
    if comment.post_block_id.nil?
      # 일반 댓글: 자식 댓글 중 블럭 연결이 없는 것만
      comment.children.where(post_block_id: nil).count
    else
      # 블럭 댓글: 같은 블럭에 있고, 이 댓글을 부모로 가지는 것
      Comment.where(parent_id: comment.id, post_block_id: comment.post_block_id).count
    end
  end

def total_comments_count(post)
  Comment.where(post_id: post.id).count
end

end

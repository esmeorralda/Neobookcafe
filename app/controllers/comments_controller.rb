class CommentsController < ApplicationController
    before_action :authenticate_user!


  before_action :set_comment, only: [:edit, :update, :destroy]
    # def create
    #   @comment = Comment.new(comment_params)
    #   @comment.user = current_user
    #   if @comment.save
    #     redirect_to post_path(@comment.post), notice: "댓글이 작성되었습니다."
    #   else
    #     redirect_to post_path(@comment.post), alert: "댓글 작성에 실패했습니다."
    #   end
    # end

    def edit
    # 편집 폼을 보여주기 위한 액션
  end
  def update
    @comment.assign_attributes(comment_params)
    full_text = @comment.content.to_s
  
    # --- profanity (Korcen) ---
    if (results = KorcenFilterService.analyze_text(full_text)).any?
      flash[:alert] = build_korcen_alert(results)
      # ✅ tell show page to open this comment's edit form and preload text
      flash[:edit_comment_id]     = @comment.id
      flash[:edit_comment_draft]  = full_text
      return redirect_to post_path(@comment.post)
    end
  
    # --- moderation (OpenAI wrapper) ---
    if (flagged = ModerationChecker.check(full_text))
      flash[:alert] = build_moderation_alert(flagged)
      flash[:edit_comment_id]    = @comment.id
      flash[:edit_comment_draft] = full_text
      return redirect_to post_path(@comment.post)
    end
  
    if @comment.save
      redirect_to post_path(@comment.post), notice: "댓글이 성공적으로 수정되었습니다."
    else
      flash[:alert] = @comment.errors.full_messages.join(", ")
      redirect_to post_path(@comment.post)
    end
  end
  


def destroy
  @comment.destroy
  # 댓글 삭제 후, 해당 댓글이 속한 포스트로 리다이렉트
  respond_to do |format|
    format.html { redirect_to @comment.post, notice: "댓글이 삭제되었습니다." }
    format.json { head :no_content }
  end
  
end

def create
  @comment = Comment.new(comment_params)
  @comment.user = current_user

  full_text = @comment.content.to_s

  # --- profanity check (Korcen) ---
  if (results = KorcenFilterService.analyze_text(full_text)).any?
    alert_msg = build_korcen_alert(results)
    flash[:alert] = alert_msg
    # ✅ keep what user typed + context for where to restore
    flash[:new_comment_draft]   = full_text
    flash[:draft_parent_id]     = comment_params[:parent_id]
    flash[:draft_post_block_id] = comment_params[:post_block_id]
    return redirect_to post_path(@comment.post)
  end

  # --- moderation check (OpenAI wrapper) ---
  if (flagged = ModerationChecker.check(full_text))
    flash[:alert] = build_moderation_alert(flagged)
    flash[:new_comment_draft]   = full_text
    flash[:draft_parent_id]     = comment_params[:parent_id]
    flash[:draft_post_block_id] = comment_params[:post_block_id]
    return redirect_to post_path(@comment.post)
  end

  if @comment.save
    redirect_to post_path(@comment.post), notice: "댓글이 등록되었습니다."
  else
    flash[:alert] = @comment.errors.full_messages.join(", ")
    redirect_to post_path(@comment.post)
  end
end

    private


    def build_korcen_alert(results)
      details = results.map do |r|
        sentence = clean_sentence(r[:sentence])
        cats = r[:categories].select { |_, v| v }.keys.map { |c| korean_reason_map(c.to_s) }.join(", ")
        "문장: #{sentence}\n감지된 비속어 유형: #{cats}"
      end.join("\n\n")
      "비속어가 포함된 문장이 감지되었습니다:\n\n#{details}\n\n이는 청소년 보호 정책의 일환으로 제한됩니다. 문장을 수정하여 다시 시도해 주세요."
    end
    
    def build_moderation_alert(flagged)
      translations = moderation_category_translations
      list = (flagged.is_a?(Array) && flagged.first.is_a?(Array) ? flagged : [flagged])
      cats = list.map { |cat, score| "#{translations[cat]} (#{(score.to_f * 100).round(1)}%)" }.compact
      "⚠️ 다음과 같은 유해 콘텐츠가 포함되어 있습니다: #{cats.join(', ')}. 수정 후 다시 시도해 주세요."
    end

    def set_post
    @post = Post.find(params[:post_id])
  end

def set_comment
  @comment = Comment.find(params[:id])
  @post = @comment.post
end

def korean_reason_map(category)
  case category
  when "general" then "일반 비속어"
  when "minor" then "경미한 비속어"
  when "sexual" then "성적 비속어"
  when "belittle" then "모욕적 표현"
  when "race" then "인종차별적 표현"
  when "parents" then "가족 비하"
  when "foreign" then "외국인 비하"
  when "special" then "특수 비속어"
  when "politics" then "정치적 비속어"
  else category
  end
end

def moderation_category_translations
  {
    "sexual" => "성적 내용",
    "hate" => "증오 발언",
    "harassment" => "괴롭힘",
    "self-harm" => "자해",
    "sexual/minors" => "아동 성적 내용",
    "hate/threatening" => "위협적인 증오 발언",
    "violence/graphic" => "노골적인 폭력",
    "self-harm/intent" => "자해 의도",
    "self-harm/instructions" => "자해 방법 안내",
    "harassment/threatening" => "위협적인 괴롭힘",
    "violence" => "폭력"
  }
end


def clean_sentence(text)
  text.gsub(/[\r\n\t]+/, " ")  # 줄바꿈과 탭을 공백으로 변환
      .gsub(/[\d,]+/, "")      # 숫자와 쉼표 제거
      .strip                   # 앞뒤 공백 제거
end

  
    def comment_params
      params.require(:comment).permit(:content, :post_id, :post_block_id, :parent_id)
    end    
  end
  
# frozen_string_literal: true

module NotifierHelper

  # @param post [Post] The post object.
  # @param opts [Hash] Optional hash.  Accepts :length parameters.
  # @return [String] The formatted post.
  def post_message(post, opts={})
    if post.respond_to? :message
      post.message.try(:plain_text_without_markdown).presence || post_page_title(post)
    else
      I18n.translate 'notifier.a_post_you_shared'
    end
  end

  # @param comment [Comment] The comment to process.
  # @return [String] The formatted comment.
  def comment_message(comment, opts={})
    if comment.post.public?
      comment.message.plain_text_without_markdown
    else
      I18n.translate 'notifier.a_limited_post_comment'
    end
  end

  def comment_message_encrypted(comment, opts={})
    encrypt(comment.message.plain_text_without_markdown) if encrypt?
  end

  def private_message_encrypted(pm, opts={})
    user = User.find_by_id(@recipient_id)
    encrypt(pm.last_unread_message(user).text) if encrypt?
  end

  private
    def encrypt?
      return false if @recipient_id.nil?
      pgp = EmailPgpKey.find_by(owner_id: @recipient_id)
      return false if pgp.nil? || !pgp.enabled?
      @fingerprint = pgp.fingerprint
      !@fingerprint.nil?
    end

    def encrypt(plain)
      plain_data = GPGME::Data.new(plain)
      GPGME::Ctx.new(:armor => true) do |c|
        keys = [c.get_key(@fingerprint)]
        return c.encrypt(
          keys, plain_data,
          GPGME::Data.new,
          GPGME::ENCRYPT_ALWAYS_TRUST)
      end
    rescue
      # incase something went wrong
      # e.g.
      #
      # GPGME::Error::UnusablePublicKey => exc
      # GPGME::Error::UnusableSecretKey => exc
      nil
    end
end

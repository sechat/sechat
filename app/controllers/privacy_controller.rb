class PrivacyController < ApplicationController
  before_action :authenticate_user!

  def update
    if params[:key]
      pgp = EmailPgpKey.find_or_initialize_by(owner_id: current_user.id)
      unless params[:key].empty?
        pgp.fingerprint = validate_pub_key(params[:key])
      else
        delete_pub_key(pgp.fingerprint)
      end
      pgp.key = params[:key]
      pgp.enabled = params[:key].empty? ? false : true
      if pgp.save
        redirect_to privacy_settings_path,
          notice: t('users.update.settings_updated')
        return
      end
    end
    redirect_to privacy_settings_path,
      notice: t('users.update.settings_not_updated')
  end

  private
    def delete_pub_key(fingerprint)
      GPGME::Ctx.new do |c|
        key = c.get_key(fingerprint)
        c.delete(key)
      end
    rescue
      # TODO report this to user
    end

    def validate_pub_key(pubkey)
      GPGME::Ctx.new do |c|
        c.import(GPGME::Data.new(pubkey))
        # and return the fingerprint
        return c.keys.last.fingerprint
      end
    rescue
      # TODO report this to user
      # incase someone is using
      # an invalid pgp key
      nil
    end
end

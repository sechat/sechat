module Workers
  class ReceiveBase < Base
    sidekiq_options queue: :urgent

    include Diaspora::Logging

    # don't retry for errors that will fail again
    def filter_errors_for_retry
      yield
    rescue DiasporaFederation::Entity::ValidationError,
           DiasporaFederation::Entity::InvalidRootNode,
           DiasporaFederation::Entity::InvalidEntityName,
           DiasporaFederation::Entity::UnknownEntity,
           DiasporaFederation::Entities::Relayable::SignatureVerificationFailed,
           DiasporaFederation::Entities::Participation::ParentNotLocal,
           DiasporaFederation::Federation::Receiver::InvalidSender,
           DiasporaFederation::Federation::Receiver::NotPublic,
           DiasporaFederation::Salmon::SenderKeyNotFound,
           DiasporaFederation::Salmon::InvalidEnvelope,
           DiasporaFederation::Salmon::InvalidSignature,
           DiasporaFederation::Salmon::InvalidDataType,
           DiasporaFederation::Salmon::InvalidAlgorithm,
           DiasporaFederation::Salmon::InvalidEncoding,
           Diaspora::Federation::AuthorIgnored,
           Diaspora::Federation::InvalidAuthor,
           # TODO: deprecated
           DiasporaFederation::Salmon::MissingMagicEnvelope,
           DiasporaFederation::Salmon::MissingAuthor,
           DiasporaFederation::Salmon::MissingHeader,
           DiasporaFederation::Salmon::InvalidHeader => e
      logger.warn "don't retry for error: #{e.class}"
    end

    def blacklisted?(data, legacy, rsa_key=nil)
      blacklist = AppConfig.blacklist.to_a
      magic_env = if legacy
        if rsa_key.nil?
          DiasporaFederation::Salmon::Slap.from_xml(data)
        else
          DiasporaFederation::Salmon::EncryptedSlap.from_xml(data, rsa_key)
        end
      else
        if rsa_key.nil?
          magic_env_xml = Nokogiri::XML::Document.parse(data).root
          DiasporaFederation::Salmon::MagicEnvelope.unenvelop(magic_env_xml)
        else
          magic_env_xml = Salmon::EncryptedMagicEnvelope.decrypt(data, rsa_key)
          DiasporaFederation::Salmon::MagicEnvelope.unenvelop(magic_env_xml)
        end
      end
      blacklist.each {|sheep|
        if sheep.eql? magic_env.sender
          logger.info "#{magic_env.sender} is blacklisted! Skipping.."
          return true
        end
      }
      false
    rescue Exception => e
      logger.warn "Exception while checking blacklist: #{e.message}"
      false
    end
  end
end

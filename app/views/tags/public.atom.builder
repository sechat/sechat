atom_feed("xmlns:thr"       => "http://purl.org/syndication/thread/1.0",
          "xmlns:georss"    => "http://www.georss.org/georss",
          "xmlns:activity"  => "http://activitystrea.ms/spec/1.0/",
          "xmlns:media"     => "http://purl.org/syndication/atommedia",
          "xmlns:poco"      => "http://portablecontacts.net/spec/1.0",
          "xmlns:ostatus"   => "http://ostatus.org/schema/1.0",
          "xmlns:statusnet" => "http://status.net/schema/api/1/",
          :id               => "#{AppConfig.pod_uri.to_s}/public_tag/#{@stream.tag_name}.atom",
          :root_url         => AppConfig.pod_uri.to_s) do |feed|

  feed.tag! :generator, 'Diaspora', :uri => "#{AppConfig.pod_uri.to_s}"
  feed.title "#{@stream.tag_name} Tag Feed"
  feed.subtitle "Updates from #{@stream.tag_name} on #{AppConfig.settings.pod_name}"
  feed.updated @stream.stream_posts[0].created_at if @stream.stream_posts.length > 0
  feed.tag! :link, :href => "#{AppConfig.environment.pubsub_server}", :rel => 'hub'

  @stream.stream_posts.each do |post|
    feed.entry post, :url => "#{AppConfig.pod_uri.to_s}p/#{post.id}",
      :id => "#{AppConfig.pod_uri.to_s}p/#{post.id}" do |entry|

      entry.title post.message.title
      entry.content post.message.markdownified(disable_hovercards: true), :type => 'html'
      entry.tag! 'activity:verb', 'http://activitystrea.ms/schema/1.0/post'
      entry.tag! 'activity:object-type', 'http://activitystrea.ms/schema/1.0/note'
    end
  end
end

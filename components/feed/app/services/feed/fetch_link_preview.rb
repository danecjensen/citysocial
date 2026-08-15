require "ipaddr"
require "net/http"
require "resolv"

module Feed
  class FetchLinkPreview
    class Error < StandardError; end

    Result = Data.define(:title, :description, :site_name, :image_io, :image_content_type, :image_filename)
    Response = Data.define(:body, :content_type, :uri)

    HTML_LIMIT = 1.megabyte
    IMAGE_LIMIT = 5.megabytes
    REDIRECT_LIMIT = 3
    OPEN_TIMEOUT = 3
    READ_TIMEOUT = 5
    ALLOWED_IMAGE_TYPES = Feed::Post::IMAGE_CONTENT_TYPES.freeze
    BLOCKED_NETWORKS = %w[
      0.0.0.0/8 10.0.0.0/8 100.64.0.0/10 127.0.0.0/8 169.254.0.0/16
      172.16.0.0/12 192.0.0.0/24 192.0.2.0/24 192.168.0.0/16 198.18.0.0/15
      198.51.100.0/24 203.0.113.0/24 224.0.0.0/4 240.0.0.0/4
      ::/128 ::1/128 fc00::/7 fe80::/10 ff00::/8 2001:db8::/32
    ].map { |network| IPAddr.new(network) }.freeze

    def self.call(url)
      new.call(url)
    end

    def call(url)
      page = fetch(url, limit: HTML_LIMIT, accept: "text/html,application/xhtml+xml")
      raise Error, "link did not return HTML" unless page.content_type.in?(%w[text/html application/xhtml+xml])

      document = Nokogiri::HTML(page.body)
      image = fetch_image(document, page.uri)

      Result.new(
        title: metadata(document, "og:title") || metadata(document, "twitter:title") || document.at_css("title")&.text,
        description: metadata(document, "og:description") || metadata(document, "twitter:description") ||
                     metadata(document, "description", attribute: "name"),
        site_name: metadata(document, "og:site_name") || page.uri.host.delete_prefix("www."),
        image_io: image&.fetch(:io),
        image_content_type: image&.fetch(:content_type),
        image_filename: image&.fetch(:filename)
      )
    end

    private

    def metadata(document, key, attribute: "property")
      value = document.at_css(%(meta[#{attribute}="#{key}"]))&.[]("content")
      value.to_s.strip.presence
    end

    def fetch_image(document, base_uri)
      raw_url = metadata(document, "og:image") || metadata(document, "twitter:image") ||
                metadata(document, "twitter:image:src")
      return if raw_url.blank?

      image_uri = URI.join(base_uri.to_s, raw_url)
      response = fetch(image_uri, limit: IMAGE_LIMIT, accept: "image/*")
      io = StringIO.new(response.body)
      content_type = Marcel::MimeType.for(io)
      return unless content_type.in?(ALLOWED_IMAGE_TYPES)

      io.rewind
      {
        io: io,
        content_type: content_type,
        filename: "article-preview#{extension_for(content_type)}"
      }
    rescue Error, URI::InvalidURIError
      nil
    end

    def extension_for(content_type)
      {
        "image/jpeg" => ".jpg",
        "image/png" => ".png",
        "image/webp" => ".webp",
        "image/gif" => ".gif"
      }.fetch(content_type)
    end

    def fetch(url, limit:, accept:, redirects: REDIRECT_LIMIT)
      uri, ip_address = public_uri!(url)
      response = request(uri, ip_address, accept: accept, limit: limit)

      if response.is_a?(Net::HTTPRedirection)
        raise Error, "too many redirects" if redirects.zero?

        location = response.fetch("location")
        return fetch(URI.join(uri.to_s, location), limit: limit, accept: accept, redirects: redirects - 1)
      end
      raise Error, "remote server returned #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      Response.new(body: response.body, content_type: response.content_type.to_s.downcase, uri: uri)
    rescue SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::HTTPError => e
      raise Error, e.message
    end

    def request(uri, ip_address, accept:, limit:)
      http = Net::HTTP.new(uri.host, uri.port, nil)
      http.ipaddr = ip_address
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = OPEN_TIMEOUT
      http.read_timeout = READ_TIMEOUT
      http.write_timeout = READ_TIMEOUT

      request = Net::HTTP::Get.new(uri.request_uri, "Accept" => accept, "User-Agent" => "CitySocial/1.0")
      http.request(request) do |response|
        return response if response.is_a?(Net::HTTPRedirection)

        body = +""
        response.read_body do |chunk|
          body << chunk
          raise Error, "remote response is too large" if body.bytesize > limit
        end
        response.body = body
        response
      end
    end

    def public_uri!(raw_url)
      uri = raw_url.is_a?(URI) ? raw_url : URI.parse(raw_url.to_s)
      unless uri.is_a?(URI::HTTP) && uri.host.present? && uri.userinfo.blank? && uri.port.in?([80, 443])
        raise Error, "URL must be public HTTP or HTTPS"
      end

      addresses = Resolv.getaddresses(uri.host)
      raise Error, "host could not be resolved" if addresses.empty?

      parsed = addresses.map { |address| IPAddr.new(address) }
      raise Error, "private network URLs are not allowed" if parsed.any? { |ip| blocked?(ip) }

      [uri, parsed.first.to_s]
    rescue URI::InvalidURIError, IPAddr::InvalidAddressError => e
      raise Error, e.message
    end

    def blocked?(ip)
      candidate = ip.ipv4_mapped? ? ip.native : ip
      BLOCKED_NETWORKS.any? { |network| network.include?(candidate) }
    end
  end
end

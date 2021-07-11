require 'bundler/setup'
require 'net/https'
require 'aws-sdk-cloudfront'
require 'aws-sdk-acm'

def fetch_chain(domain)
  uri = URI.parse("https://#{domain}")
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    return http.instance_variable_get(:@socket).io.peer_cert_chain
  end
end

def make_nonmatching_private_key(chain)
  chain = chain.dup
  leaf = chain.shift
  private_key = OpenSSL::PKey::RSA.new(2048)
  private_key.set_key(leaf.public_key.n, leaf.public_key.e, leaf.public_key.d)

  [leaf, chain, private_key]
end

def import_to_acm(certificate, chain, private_key)
  client = Aws::ACM::Client.new
  client.import_certificate(
    certificate: certificate,
    private_key: private_key,
    certificate_chain: chain
  )
end

def list_conflicting_aliases(distribution_id, domain)
  client = Aws::CloudFront::Client.new
  client.list_conflicting_aliases(
    distribution_id: distribution_id,
    alias: domain
  )
end

client = Aws::CloudFront::Client.new
pp client.list_conflicting_aliases(
  distribution_id: 'EBWXJJWLU8T6O',
  alias: 'buzzfeed.com'
)

# import_to_acm(IO.read('buzzfeed.com_certificate.pem'), IO.read('buzzfeed.com_chain.pem'), IO.read('buzzfeed.com_private_key.pem'))

# domain = 'buzzfeed.com'
# chain = fetch_chain(domain)
# leaf, chain, private_key = *make_nonmatching_chain(chain)
# IO.write("#{domain}_certificate.pem", leaf.to_pem)
# IO.write("#{domain}_chain.pem", chain.map(&:to_pem).join("\n"))
# IO.write("#{domain}_private_key.pem", private_key.to_pem)

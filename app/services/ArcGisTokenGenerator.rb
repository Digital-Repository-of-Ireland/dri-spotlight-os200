class ArcGisTokenGenerator

  def initialize
      @client ||= RestClient::Resource.new(Mapping.token_url)
  end

  def token
    response = @client["/generateToken?f=json"].post({ username: Mapping.username, password: Mapping.password, referer: 'clientip' }, { accept: :json })
    JSON.parse(response)['token']
  end
end
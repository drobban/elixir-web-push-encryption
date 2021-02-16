defmodule WebPushEncryption.Vapid do
  # aes128gcm not yet supported in push.ex
  @supported_encodings ~w(aesgcm)

  def get_headers(audience, content_encoding, expiration \\ 12 * 3600, vapid \\ nil)
      when content_encoding in @supported_encodings do
    expiration_timestamp = DateTime.to_unix(DateTime.utc_now()) + expiration

    vapid = vapid || Application.fetch_env!(:web_push_encryption, :vapid_details)

    _public_key = Base.url_decode64!(vapid[:public_key], padding: false)
    private_key = Base.url_decode64!(vapid[:private_key], padding: false)

    payload =
      %{
        aud: audience,
        exp: expiration_timestamp,
        sub: vapid[:subject]
      }
      |> JOSE.JWT.from_map()

    jwk = JOSE.JWK.from_der(private_key)

    {_, jwt} = JOSE.JWS.compact(JOSE.JWT.sign(jwk, %{"alg" => "ES256"}, payload))
    headers(content_encoding, jwt, vapid[:public_key])
  end

  def get_headers_with_key(
        %{:priv => priv, :pub => pub},
        audience,
        content_encoding,
        expiration \\ 12 * 3600,
        vapid \\ nil
      )
      when content_encoding in @supported_encodings do
    expiration_timestamp = DateTime.to_unix(DateTime.utc_now()) + expiration

    public_key = Base.url_decode64!(pub, padding: false)
    private_key = Base.url_decode64!(priv, padding: false)

    payload =
      %{
        aud: audience,
        exp: expiration_timestamp,
        sub: "push@local.host"
      }
      |> JOSE.JWT.from_map()

    jwk = JOSE.JWK.from_der(private_key)

    {_, jwt} = JOSE.JWS.compact(JOSE.JWT.sign(jwk, %{"alg" => "ES256"}, payload))
    headers(content_encoding, jwt, pub)
  end

  defp headers("aesgcm", jwt, pub) do
    %{"Authorization" => "WebPush " <> jwt, "Crypto-Key" => "p256ecdsa=" <> pub}
  end

  defp headers("aes128gcm", jwt, pub) do
    %{"Authorization" => "vapid t=#{jwt}, p=#{pub}"}
  end
end

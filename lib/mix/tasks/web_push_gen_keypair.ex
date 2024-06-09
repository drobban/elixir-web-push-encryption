defmodule Mix.Tasks.WebPush.Gen.Keypair do
  @moduledoc """
  Generate VAPID supplied config.

  It will output something like this; 

    config :web_push_encryption, :vapid_details,
      subject: \"mailto:administrator@example.com\",
      public_key: \"BPFoGQXYu4LgQvn_EXAMPLE_RgXSkYAEXkJO_SUP74cLsduMRd_zHd-CY7ACYQ\" ,
      private_key: \"CJ4dlX4WIm_EXAMPLE_lZevqDPKwAyxs9k\"
  """
  @shortdoc "VAPID generator"

  use Mix.Task

  def run(_) do
    {public, private} = :crypto.generate_key(:ecdh, :prime256v1)

    IO.puts("# Put the following in your config.exs:")
    IO.puts("")
    IO.puts("config :web_push_encryption, :vapid_details,")
    IO.puts("  subject: \"mailto:administrator@example.com\",")
    IO.puts("  public_key: \"#{ub64(public)}\",")
    IO.puts("  private_key: \"#{ub64(private)}\"")
    IO.puts("")
  end

  defp ub64(value) do
    Base.url_encode64(value, padding: false)
  end
end

Puppet::Type.newtype(:boundary_meter) do

  @doc = "Manage creation/deletion of Boundary meters."

  ensurable

  newparam(:meter, :namevar => true) do
    desc "The Boundary meter name"
  end

  newparam(:username) do
    desc "The Boundary user name."
  end

  newparam(:apikey) do
    desc "The Boundary API key."
  end
end

{ lib
, buildGoModule
, fetchFromGitHub
}:
buildGoModule {
  pname = "v2dat";
  version = "47b8ee5";

  src = fetchFromGitHub ({
    owner = "urlesistiana";
    repo = "v2dat";
    rev = "47b8ee51fb528e11e1a83453b7e767a18d20d1f7";
    sha256 = "sha256-dJld4hYdfnpphIEJvYsj5VvEF4snLvXZ059HJ2BXwok=";
  });

  vendorHash = "sha256-ndWasQUHt35D528PyGan6JGXh5TthpOhyJI2xBDn0zI=";

  meta = with lib; {
    description = "A cli tool that can unpack v2ray data packages.";
    homepage = "https://github.com/urlesistiana/v2dat";
    license = licenses.gpl3;
  };
}
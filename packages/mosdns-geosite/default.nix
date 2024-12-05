{ stdenvNoCC
, v2ray-rules-dat
, v2dat
}:

stdenvNoCC.mkDerivation {
  pname = "v2ray-geosite";
  version = "latest";

  src = v2ray-rules-dat;

  nativeBuildInputs = [ v2dat ];

  installPhase = ''
    runHook preInstall
    mkdir $out
    v2dat unpack geosite -o $out geosite.dat
    runHook postInstall
  '';
}
{ stdenvNoCC
, v2ray-rules-dat
}:

stdenvNoCC.mkDerivation {
  pname = "v2dat-geoip";
  version = "latest";

  src = v2ray-rules-dat;

  installPhase = ''
    runHook preInstall
    install -Dm444 -t "$out/share/v2ray" geoip.dat
    runHook postInstall
  '';
}
{ lib
, stdenvNoCC
, nodejs-18_x
, nodejs-slim-18_x
, fetchNodeModules
, fetchpatch
, fetchurl
, makeWrapper
}:
let self = stdenvNoCC.mkDerivation {
  pname = "rtl";
  version = "0.15.4";

  src = fetchurl {
    url = "https://github.com/Ride-The-Lightning/RTL/archive/refs/tags/v${self.version}.tar.gz";
    hash = "sha256-vHno0vMtT5fjtDG2hWGDZP2a34JrFWvqfIgIgvOTv08=";
  };

  passthru = {
    nodejs = nodejs-18_x;
    nodejsRuntime = nodejs-slim-18_x;

    nodeModules = fetchNodeModules {
      inherit (self) src nodejs;
      # TODO-EXTERNAL: Remove `npmFlags` when no longer required
      # See: https://github.com/Ride-The-Lightning/RTL/issues/1182
      npmFlags = "--legacy-peer-deps";
      hash = "sha256-1x2IukpS85hEw3nmHl1dxNF5mXDmEX6H8pHve/MxWks=";
    };
  };

  nativeBuildInputs = [
    makeWrapper
  ];

  phases = "unpackPhase patchPhase installPhase";

  # `src` already contains the precompiled frontend and backend.
  # Copy all files required for packaging, like in
  # https://github.com/Ride-The-Lightning/RTL/blob/master/dockerfiles/Dockerfile
  installPhase = ''
    dest=$out/lib/node_modules/rtl
    mkdir -p $dest
    cp -r \
      rtl.js \
      package.json \
      frontend \
      backend \
      ${self.nodeModules}/lib/node_modules \
      $dest

    makeWrapper ${self.nodejsRuntime}/bin/node "$out/bin/rtl" \
      --add-flags "$dest/rtl.js"

    runHook postInstall
  '';

  meta = with lib; {
    description = "A web interface for LND, c-lightning and Eclair";
    homepage = "https://github.com/Ride-The-Lightning/RTL";
    license = licenses.mit;
    maintainers = with maintainers; [ nixbitcoin erikarvstedt ];
    platforms = platforms.unix;
  };
}; in self

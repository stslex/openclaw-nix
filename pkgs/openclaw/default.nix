{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_22,
  makeWrapper,
  python3,
  pkg-config,
  jq,
  ...
}:

let
  versionInfo = lib.importJSON ./version.json;
in
buildNpmPackage rec {
  pname = "openclaw";
  version = versionInfo.version;

  src = fetchurl {
    url = "https://registry.npmjs.org/openclaw/-/openclaw-${version}.tgz";
    hash = versionInfo.tarballHash;
  };

  sourceRoot = "package";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json

    # Newer tarballs ship an npm-shrinkwrap.json, which npm prefers over the
    # package-lock.json we pin against. Drop it so the build resolves deps from
    # our lockfile (which the npmDepsHash is computed from).
    rm -f npm-shrinkwrap.json

    # The tarball ships without source scripts that prepack/postinstall reference.
    # Remove lifecycle hooks that are only useful for development builds.
    ${jq}/bin/jq 'del(.scripts.preinstall, .scripts.prepack, .scripts.postinstall, .scripts.prepare)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  npmDepsHash = versionInfo.npmDepsHash;

  nodejs = nodejs_22;

  nativeBuildInputs = [
    makeWrapper
    python3
    pkg-config
  ];

  npmFlags = [ "--legacy-peer-deps" ];
  makeCacheWritable = true;

  dontNpmBuild = true;

  meta = {
    description = "Multi-channel AI gateway with extensible messaging integrations";
    homepage = "https://github.com/openclaw/openclaw";
    license = lib.licenses.mit;
    mainProgram = "openclaw";
    platforms = lib.platforms.unix;
  };
}

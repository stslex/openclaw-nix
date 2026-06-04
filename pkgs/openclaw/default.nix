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

    # The published tarball ships a prebuilt dist/ and a plain openclaw.mjs bin,
    # so none of the package's own lifecycle scripts are needed to package it
    # (dontNpmBuild is set). Those scripts reference dev-only source files that
    # aren't shipped (e.g. preinstall, prepack/postpack which call
    # scripts/package-changelog.mjs, postinstall, prepare), and npm runs
    # prepack/postpack during the install phase's `npm pack`, failing the build.
    # Drop the whole scripts object so new releases adding more hooks don't break
    # the build. Dependency install scripts live in node_modules and are
    # unaffected.
    ${jq}/bin/jq 'del(.scripts)' package.json > package.json.tmp
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

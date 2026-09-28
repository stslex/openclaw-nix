{
  lib,
  buildNpmPackage,
  fetchurl,
  nodejs_24,
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
    #
    # bundleDependencies goes too, along with the node_modules/ the tarball ships
    # for it (chrome-devtools-mcp since 2026.9). scripts/update.sh resolves it
    # from the registry so prefetch-npm-deps caches it; left bundled, the lockfile
    # entry has no resolved/integrity and the offline install fails with
    # ENOTCACHED.
    ${jq}/bin/jq 'del(.scripts, .bundleDependencies, .bundledDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
    rm -rf node_modules
  '';

  # The tarball ships a .openclaw-lifecycle-pending marker that its postinstall
  # removes. With `scripts` dropped above nothing does, and the CLI then tries to
  # finish the lifecycle on first run by writing into the read-only store
  # (EACCES on .openclaw-lifecycle-lock). Run that postinstall here instead,
  # while $out is still writable.
  postInstall = ''
    pushd $out/lib/node_modules/openclaw
    ${nodejs_24}/bin/node scripts/postinstall-bundled-plugins.mjs
    popd
    test ! -e $out/lib/node_modules/openclaw/.openclaw-lifecycle-pending
  '';

  npmDepsHash = versionInfo.npmDepsHash;

  nodejs = nodejs_24;

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

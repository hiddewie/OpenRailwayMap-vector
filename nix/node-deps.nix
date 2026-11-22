# The npm packages (`yaml`, `chroma-js`) that the code generators in
# import/, proxy/js and api/ import. Node's ESM loader ignores NODE_PATH, so
# the generators are run from a directory that has this node_modules in it.
{ buildNpmPackage }:
buildNpmPackage {
  pname = "openrailwaymap-node-deps";
  version = "0.0.0";
  src = ./node-deps;
  npmDepsHash = "sha256-Bo9dxI0zxJcSYvqtjXsGJcG/N4kY+n2L+ar8Gl88C+Q=";
  dontNpmBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -r node_modules $out/
  '';
}

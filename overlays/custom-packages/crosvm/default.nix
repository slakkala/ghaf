final: { lib, rustPlatform, fetchgit, fetchpatch
, pkg-config, protobuf, python3, wayland-scanner
, libcap, libdrm, libepoxy, minijail, virglrenderer, wayland, wayland-protocols,
...}: {

  crosvm = rustPlatform.buildRustPackage rec {
  pname = "crosvm";
  version = "122.0";

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/platform/crosvm";
    rev = "562d81eb28a49ed6e0d771a430c21a458cdd33f9";
    sha256 = "l5sIUInOhhkn3ernQLIEwEpRCyICDH/1k4C/aidy1/I=";
    fetchSubmodules = true;
  };

  patches = [ ./0001-TESTING.patch ];
  separateDebugInfo = true;

  cargoHash = "sha256-57gYhvlejhRznYq1UfmXW+qagaS5cbUOzjPATDyluXY=";

  nativeBuildInputs = [
    pkg-config protobuf python3 rustPlatform.bindgenHook wayland-scanner
  ];

  buildInputs = [
    libcap libdrm libepoxy minijail virglrenderer wayland wayland-protocols
  ];

  preConfigure = ''
    patchShebangs third_party/minijail/tools/*.py
  '';

  CROSVM_USE_SYSTEM_VIRGLRENDERER = true;
  CROSVM_USE_SYSTEM_MINIGBM = true;

  buildFeatures = [ "default" "virgl_renderer" ];

  passthru.updateScript = ./update.py;

  meta = with lib; {
    description = "A secure virtual machine monitor for KVM";
    homepage = "https://crosvm.dev/";
    mainProgram = "crosvm";
    maintainers = with maintainers; [ qyliss ];
    license = licenses.bsd3;
    platforms = [ "aarch64-linux" "x86_64-linux" ];
  };
};
}

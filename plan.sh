pkg_name=git-studio
pkg_origin=jarvus
pkg_version="0.6.1"
pkg_maintainer="Chris Alfano <chris@jarv.us>"
pkg_license=("MIT")
pkg_deps=(
  core/git
  core/openssh
  core/cacerts
)


do_build() {
  return 0
}

do_install() {
  cp -v "${PLAN_CONTEXT}/studio.sh" "${pkg_prefix}/"
}

do_strip() {
  return 0
}
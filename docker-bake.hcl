variable "VERSION" {
    default = "0.0.1-alpha3"
}

variable "USER" {}

variable "GO_VERSION" {
  default = "1.23.5"
}

group "default" {
    targets = [
        "workbench",
    ]
}

group "all" {
  targets = ["workbench", "workbench-dist"]
}

target "workbench-base" {
    context    = "."
    dockerfile = "Dockerfile"
    target     = "workbench"
    ssh        = ["default"]
}

target "workbench" {
    matrix = {
        item = [
            {
              RUST_VERSION = "1.96.0"
              DEBIAN_VERSION = "bookworm"
            },
            {
              RUST_VERSION = "1.96.0",
              DEBIAN_VERSION = "trixie"
            },
        ]
    }
    name       = "workbench_${replace(item.RUST_VERSION, ".", "-")}_${item.DEBIAN_VERSION}"
    inherit    = ["workbench-base"]
    tags       = [
        "harrybrwn/workbench:${VERSION}-${item.DEBIAN_VERSION}"
    ]
    args = {
        VERSION        = trimprefix(VERSION, "v")
        RUST_VERSION   = item.RUST_VERSION
        DEBIAN_VERSION = item.DEBIAN_VERSION
        USER           = "${USER}"
        GO_VERSION     = "${GO_VERSION}"
    }
}

target "workbench-dist" {
    matrix = {
        item = [
            # { RUST_VERSION = "1.84.0-bullseye", DEBIAN_VERSION = "bullseye" },
            {
              RUST_VERSION   = "1.96.0",
              DEBIAN_VERSION = "bookworm"
            },
            {
              RUST_VERSION   = "1.96.0",
              DEBIAN_VERSION = "trixie"
            },
        ]
    }
    name       = "workbench-dist_${replace(item.RUST_VERSION, ".", "-")}_${item.DEBIAN_VERSION}"
    inherit    = ["workbench-base"]
    tags       = [
        "harrybrwn/workbench-dist:${VERSION}-${item.DEBIAN_VERSION}"
    ]
    args = {
        VERSION        = trimprefix(VERSION, "v")
        RUST_VERSION   = item.RUST_VERSION
        DEBIAN_VERSION = item.DEBIAN_VERSION
        USER           = "${USER}"
        GO_VERSION     = "${GO_VERSION}"
    }
    ssh = ["default"]
    output = [
        "type=local,dest=docker-build"
    ]
}

target "builder" {
    context = "."
    dockerfile = "Dockerfile"
    target = "builder"
    tags = ["workbench-builder"]
    args = {
        VERSION        = trimprefix(VERSION, "v")
        RUST_VERSION   = "1.84.0-bookworm"
        DEBIAN_VERSION = "bookworm"
        USER           = "${USER}"
        GO_VERSION     = "${GO_VERSION}"
    }
    ssh = ["default"]
}

target "sshtest" {
    context = "."
    dockerfile = "Dockerfile"
    target = "sshtest"
    # tags = ["workbench-builder"]
    args = {
        VERSION        = trimprefix(VERSION, "v")
        RUST_VERSION   = "1.96.0"
        DEBIAN_VERSION = "trixie"
        GO_VERSION     = "${GO_VERSION}"
    }
    ssh = ["default"]
}
